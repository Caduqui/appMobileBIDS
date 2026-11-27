#!/usr/bin/env bash
# Trata um efeito sonoro ou uma música de fundo antes de ir pro app:
#
#   bash tool/treat_sound.sh sfx   <entrada> <saída.wav>
#   bash tool/treat_sound.sh music <entrada> <saída.mp3>
#
# Primo do tool/treat_audio.sh (que é pras falas). Os dois levam o volume
# médio a um alvo fixo com ganho constante + limitador, pra todos os arquivos
# de um tipo soarem no mesmo volume e o volume do player (MusicTrack.volume,
# GameAudio.sfxVolume) valer igual pra todos.
#
# sfx:   corta o silêncio do começo e do fim (silêncio no começo = som
#        atrasado no toque), volume médio a -18 dB, WAV mono 44,1 kHz 16 bits.
#        WAV e não mp3: abre sem decodificar e o mp3 sempre põe um silêncio
#        de ~25 ms no começo. Os arquivos são minúsculos (< 100 KB).
# music: NÃO corta nada (a faixa precisa emendar o fim no começo pro loop),
#        volume médio a -20 dB, mp3 estéreo 44,1 kHz 112 kbps. Ganho constante
#        de propósito: um normalizador dinâmico (loudnorm) deixaria o fim e o
#        começo com volumes diferentes e o loop daria um degrau.
#
# Precisa do ffmpeg (variável FFMPEG ou ffmpeg no PATH).
set -euo pipefail
FF="${FFMPEG:-ffmpeg}"
kind="$1"; in="$2"; out="$3"
base="$(mktemp -u)"
case "$kind" in
  sfx)
    trim="silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.005,areverse,silenceremove=start_periods=1:start_threshold=-60dB:start_silence=0.02,areverse"
    "$FF" -v error -y -i "$in" -af "$trim" -ac 1 -ar 44100 "$base.a.wav"
    target=-18; codec=(-c:a pcm_s16le); channels=1
    ;;
  music)
    "$FF" -v error -y -i "$in" -ac 2 -ar 44100 "$base.a.wav"
    target=-20; codec=(-c:a libmp3lame -b:a 112k); channels=2
    ;;
  *) echo "tipo deve ser sfx ou music" >&2; exit 1 ;;
esac
src="$base.a.wav"
mean=$("$FF" -hide_banner -i "$src" -af volumedetect -f null - 2>&1 | sed -n 's/.*mean_volume: \(-\?[0-9.]*\) dB.*/\1/p')
gain=$(awk -v m="$mean" -v t="$target" 'BEGIN{printf "%.2f", t - m}')
"$FF" -v error -y -i "$src" -af "volume=${gain}dB,alimiter=limit=0.89:attack=2:release=40:level=false" \
  -ac "$channels" -ar 44100 "${codec[@]}" "$out"
rm -f "$base".*.wav
echo "$(basename "$out") volume=$mean dB ganho=$gain dB"
