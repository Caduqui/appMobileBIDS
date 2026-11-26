// Gera lib/data/audio_envelopes.dart: o volume de cada áudio do Sons das
// Letras a cada 10 ms, que é o que guia a boquinha (ver AGENTS.md).
//
// Rode de novo sempre que adicionar/trocar um .mp3 em assets/audio/:
//
//   dart run tool/gen_audio_envelopes.dart
//
// Precisa do ffmpeg no PATH (ou o caminho do executável na variável de
// ambiente FFMPEG) — só aqui no PC, o app não usa ffmpeg.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _folders = ['assets/audio/letters', 'assets/audio/words'];
const _sampleRate = 16000;
const _stepMs = 10;
const _windowMs = 25;

/// Faixa de volume mapeada pra 0–100. Os áudios são normalizados (média
/// ~-14 dB), então uma escala absoluta deixa todos comparáveis.
const _floorDb = -55.0;
const _ceilDb = -5.0;

Future<void> main() async {
  final ffmpeg = Platform.environment['FFMPEG'] ?? 'ffmpeg';
  final files = [
    for (final folder in _folders)
      ...Directory(folder)
          .listSync()
          .whereType<File>()
          .map((f) => f.path.replaceAll(r'\', '/'))
          .where((p) => p.endsWith('.mp3')),
  ]..sort();

  final out = StringBuffer()
    ..writeln('// GERADO por tool/gen_audio_envelopes.dart — não edite à mão.')
    ..writeln('// Rode `dart run tool/gen_audio_envelopes.dart` ao trocar um áudio.')
    ..writeln()
    ..writeln('/// Intervalo entre dois valores de [kAudioEnvelopes].')
    ..writeln('const kEnvelopeStepMs = $_stepMs;')
    ..writeln()
    ..writeln('/// Volume (0 = silêncio, 100 = bem alto) de cada áudio a cada')
    ..writeln('/// [kEnvelopeStepMs] ms, do começo ao fim do arquivo.')
    ..writeln('const kAudioEnvelopes = <String, List<int>>{');

  for (final path in files) {
    final result = await Process.run(
      ffmpeg,
      ['-v', 'error', '-i', path, '-ac', '1', '-ar', '$_sampleRate', '-f', 's16le', '-'],
      stdoutEncoding: null,
    );
    if (result.exitCode != 0) {
      stderr.writeln('ffmpeg falhou em $path: ${result.stderr}');
      exitCode = 1;
      return;
    }
    final bytes = Uint8List.fromList(result.stdout as List<int>);
    final samples = bytes.buffer.asInt16List(0, bytes.lengthInBytes ~/ 2);
    final envelope = _envelope(samples);
    out.writeln("  '$path': [${envelope.join(', ')}],");
    stdout.writeln('$path: ${envelope.length * _stepMs} ms');
  }
  out.writeln('};');
  File('lib/data/audio_envelopes.dart').writeAsStringSync(out.toString());
}

List<int> _envelope(Int16List samples) {
  const step = _sampleRate * _stepMs ~/ 1000;
  const half = _sampleRate * _windowMs ~/ 2000;
  final frames = (samples.length / step).ceil();
  return [
    for (var i = 0; i < frames; i++) _level(samples, i * step + step ~/ 2, half),
  ];
}

int _level(Int16List samples, int center, int half) {
  final start = math.max(0, center - half);
  final end = math.min(samples.length, center + half);
  if (end <= start) return 0;
  var sum = 0.0;
  for (var i = start; i < end; i++) {
    final s = samples[i] / 32768;
    sum += s * s;
  }
  final rms = math.sqrt(sum / (end - start));
  final db = 20 * math.log(math.max(rms, 1e-9)) / math.ln10;
  return (((db - _floorDb) / (_ceilDb - _floorDb)).clamp(0.0, 1.0) * 100).round();
}
