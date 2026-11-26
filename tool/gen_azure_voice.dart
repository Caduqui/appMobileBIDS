// Gera TODOS os áudios do Sons das Letras — o som de cada letra e cada
// palavra de exemplo — com a voz feminina pt-BR "Yara" da Azure
// (pt-BR-YaraNeural), escolhida pelo usuário por ser a mais parecida
// (tom ~211 Hz) com a voz das gravações originais. Ver AGENTS.md.
//
//   dart run tool/gen_azure_voice.dart <pasta de saída> [nomes...]
//
// Sem [nomes] gera tudo; com nomes, só esses (ex.: `b f queijo`), pra
// refazer um áudio. Sai um .wav por áudio em <saída>/letters e
// <saída>/words; depois trate cada um com tool/treat_audio.sh (corta,
// alonga os sons de letra, ajusta o volume e grava o .mp3), copie pra
// assets/audio/ e rode tool/gen_audio_envelopes.dart.
//
// Precisa das variáveis de ambiente AZURE_SPEECH_KEY e AZURE_SPEECH_REGION
// (recurso "Speech"/"Fala" da Azure; o nível gratuito F0 basta). Só roda
// aqui no PC — o app não fala com a Azure.
import 'dart:convert';
import 'dart:io';

const _voice = 'pt-BR-YaraNeural';

/// O SOM de cada letra (não o nome: "mmm", não "eme"), em IPA. Os que
/// estouram vêm sozinhos, sem vogal depois, como no Método das Boquinhas. A
/// voz ignora o alongamento (ː) e devolve ~0,3 s: quem alonga é
/// treat_audio.sh. O G é o "g" comum: com o "ɡ" do IPA a Azure devolve um
/// arquivo vazio.
const _letterSounds = {
  'a': 'aː',
  'e': 'ɛː',
  'i': 'iː',
  'o': 'ɔː',
  'u': 'uː',
  'b': 'b',
  'c': 'k',
  'd': 'd',
  'f': 'fːː',
  'g': 'g',
  'j': 'ʒːː',
  'l': 'lːː',
  'm': 'mːː',
  'n': 'nːː',
  'p': 'p',
  'r': 'xːː',
  's': 'sːː',
  't': 't',
  'v': 'vːː',
  'x': 'ʃːː',
  'z': 'zːː',
};

/// Letras que repetem o som de outra (o H não tem som e não tem áudio).
const _letterCopies = {'k': 'c', 'q': 'c', 'w': 'u', 'y': 'i'};

/// Palavras cuja grafia confunde a voz: texto falado no lugar do nome.
const _spoken = <String, String>{};

/// Mais devagar que a fala normal: é pra criança aprendendo. Nas letras, o
/// mínimo que a Azure aceita, pra alongar menos depois.
const _wordRate = '-40%';
const _letterRate = '-50%';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('uso: dart run tool/gen_azure_voice.dart <pasta de saída> [nomes...]');
    exitCode = 64;
    return;
  }
  final key = Platform.environment['AZURE_SPEECH_KEY'];
  final region = Platform.environment['AZURE_SPEECH_REGION'];
  if (key == null || key.isEmpty || region == null || region.isEmpty) {
    stderr.writeln('Defina AZURE_SPEECH_KEY e AZURE_SPEECH_REGION.');
    exitCode = 1;
    return;
  }
  final out = args.first;
  final only = args.skip(1).toSet();

  // As palavras são as que já têm arquivo em assets/audio/words (o teste
  // de dados garante que é exatamente a lista de palavras das fases).
  final names = _wordNames();
  final words = Directory('assets/audio/words')
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last)
      .where((n) => n.endsWith('.mp3'))
      .map((n) => n.substring(0, n.length - 4))
      .toList()
    ..sort();

  final jobs = <(String, String)>[
    for (final MapEntry(key: letter, value: ipa) in _letterSounds.entries)
      ('letters/$letter', _ssml(_phoneme(ipa, letter), _letterRate)),
    for (final id in words)
      ('words/$id', _ssml(_escape(_spoken[id] ?? names[id] ?? id), _wordRate)),
  ].where((job) => only.isEmpty || only.contains(job.$1.split('/').last)).toList();

  Directory('$out/letters').createSync(recursive: true);
  Directory('$out/words').createSync(recursive: true);
  final client = HttpClient();
  try {
    for (final (name, ssml) in jobs) {
      final audio = await _synthesize(client, region, key, ssml);
      File('$out/$name.wav').writeAsBytesSync(audio);
      stdout.writeln('$name.wav ${audio.length} bytes');
      // Nível gratuito: no máximo 20 pedidos por minuto.
      await Future<void>.delayed(const Duration(milliseconds: 3100));
    }
  } finally {
    client.close();
  }
  for (final MapEntry(key: copy, value: source) in _letterCopies.entries) {
    final src = File('$out/letters/$source.wav');
    if (src.existsSync() && (only.isEmpty || only.contains(source) || only.contains(copy))) {
      src.copySync('$out/letters/$copy.wav');
    }
  }
}

String _phoneme(String ipa, String letter) =>
    '<phoneme alphabet="ipa" ph="$ipa">$letter</phoneme>';

String _ssml(String body, String rate) =>
    '<speak version="1.0" xml:lang="pt-BR" xmlns="http://www.w3.org/2001/10/synthesis">'
    '<voice name="$_voice"><prosody rate="$rate">$body</prosody></voice></speak>';

String _escape(String text) => const HtmlEscape(HtmlEscapeMode.element).convert(text);

/// id → nome (com acento) de cada palavra do catálogo.
Map<String, String> _wordNames() {
  final source = File('lib/data/word_catalog.dart').readAsStringSync();
  final pattern = RegExp(r"WordItem\(\s*id: '([^']+)',\s*name: '([^']+)'");
  return {for (final m in pattern.allMatches(source)) m[1]!: m[2]!};
}

Future<List<int>> _synthesize(HttpClient client, String region, String key, String ssml) async {
  for (var attempt = 0; ; attempt++) {
    final request = await client.postUrl(
      Uri.parse('https://$region.tts.speech.microsoft.com/cognitiveservices/v1'),
    );
    request.headers
      ..set('Ocp-Apim-Subscription-Key', key)
      ..set('Content-Type', 'application/ssml+xml; charset=utf-8')
      ..set('X-Microsoft-OutputFormat', 'riff-24khz-16bit-mono-pcm')
      ..set('User-Agent', 'gen-azure-voice');
    request.add(utf8.encode(ssml));
    final response = await request.close();
    final bytes = await response.fold<List<int>>([], (all, chunk) => all..addAll(chunk));
    if (response.statusCode == 200) return bytes;
    if (response.statusCode == 429 && attempt < 5) {
      await Future<void>.delayed(const Duration(seconds: 10));
      continue;
    }
    throw HttpException('Azure respondeu ${response.statusCode}: ${utf8.decode(bytes, allowMalformed: true)}');
  }
}
