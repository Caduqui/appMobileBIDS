import '../models/word_item.dart';

/// Falas do Complete a Palavra, com a voz Yara (a mesma do Sons das Letras),
/// geradas por `tool/gen_azure_voice.dart` e tratadas por
/// `tool/treat_audio.sh`. Ficam em `assets/voice/`, fora de `assets/audio/`:
/// lá todo mp3 precisa de curva de volume pra boca, e aqui não há boca.
/// Caminhos relativos a `assets/` (o prefixo do audioplayers).

/// O NOME da letra ("eme", não "mmm"), falado quando a criança acerta.
String letterNameClip(String letter) =>
    'voice/letter_names/${letter.toLowerCase()}.mp3';

/// A palavra inteira, falada quando a criança completa.
String wordClip(WordItem word) => 'voice/words/${word.id}.mp3';

/// Comemorações depois da palavra completa; uma é sorteada a cada vez.
const cheerClips = [
  'voice/cheers/parabens.mp3',
  'voice/cheers/muito_bem.mp3',
  'voice/cheers/isso_ai.mp3',
];
