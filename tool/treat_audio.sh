#!/usr/bin/env bash
# Trata um áudio gerado por tool/gen_azure_voice.dart antes de ir pro app:
#
#   bash tool/treat_audio.sh <entrada.wav> <saída.mp3> [duração alvo em s]
#
# Corta o silêncio do começo e do fim (silêncio no começo atrasa o som em
# relação à boca), alonga o som até a duração alvo sem mudar o tom
# (rubberband — a Yara fala os sons isolados em ~0,3 s, curto demais pra
# criança ouvir um "mmm"), leva o volume médio a -14 dB com limitador pra não
# distorcer e grava mp3 mono 44,1 kHz 96 kbps. Durações usadas (o usuário
# pediu mais devagar, pra criança entender): vogais 0,95; R 1,1; J 1,35;
# M/N/X 1,4; F/L/V/Z 1,45; S 1,55; sons que estouram (B C D G P T) e
# palavras sem alvo (a lentidão delas vem do _wordRate do gerador). Precisa do ffmpeg com rubberband (variável FFMPEG
# ou ffmpeg no PATH). Depois rode tool/gen_audio_envelopes.dart.
set -euo pipefail
FF="${FFMPEG:-ffmpeg}"
FP="${FF%ffmpeg*}ffprobe${FF##*ffmpeg}"
in="$1"; out="$2"; target="${3:-}"
base="$(mktemp -u)"
trim="silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.01,areverse,silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.04,areverse"
"$FF" -v error -y -i "$in" -af "$trim" -ac 1 -ar 44100 "$base.a.wav"
src="$base.a.wav"
tempo=""
if [[ -n "$target" ]]; then
  dur=$("$FP" -v error -show_entries format=duration -of csv=p=0 "$src")
  tempo=$(awk -v d="$dur" -v t="$target" 'BEGIN{x=d/t; if (x>1) x=1; printf "%.4f", x}')
  "$FF" -v error -y -i "$src" -af "rubberband=tempo=$tempo:transients=smooth:window=long:pitchq=quality" "$base.b.wav"
  src="$base.b.wav"
fi
mean=$("$FF" -hide_banner -i "$src" -af volumedetect -f null - 2>&1 | sed -n 's/.*mean_volume: \(-\?[0-9.]*\) dB.*/\1/p')
gain=$(awk -v m="$mean" 'BEGIN{printf "%.2f", -14 - m}')
"$FF" -v error -y -i "$src" -af "volume=${gain}dB,alimiter=limit=0.89:attack=2:release=40:level=false" \
  -ac 1 -ar 44100 -c:a libmp3lame -b:a 96k "$out"
rm -f "$base".*.wav
echo "$(basename "$out") volume=$mean dB ganho=$gain dB${tempo:+ tempo=$tempo}"
