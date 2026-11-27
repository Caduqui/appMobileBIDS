import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/mouth_pose.dart';

/// Foto real de uma boca (Pexels, licença livre — ver AGENTS.md), de
/// frente, com os lábios fechados. Todas as letras usam esta mesma foto,
/// deformada pra cada som.
const kMouthPhotoPath = 'assets/images/mouth/mouth.jpg';

/// Mostra a "boquinha" na [pose] dada: a foto real de [kMouthPhotoPath]
/// deformada (lábios abrem, esticam, fazem bico) com o interior da boca —
/// dentes e língua — desenhado no vão que abre entre os lábios, já que a
/// foto tem a boca fechada. Não anima sozinha — quem anima é a tela,
/// trocando a pose a cada quadro.
class MouthView extends StatefulWidget {
  final MouthPose pose;

  const MouthView({super.key, required this.pose});

  @override
  State<MouthView> createState() => _MouthViewState();
}

class _MouthViewState extends State<MouthView> {
  ImageStream? _stream;
  ImageInfo? _photo;
  late final _listener = ImageStreamListener((info, _) {
    if (!mounted) {
      info.dispose();
      return;
    }
    setState(() {
      _photo?.dispose();
      _photo = info;
    });
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = const AssetImage(
      kMouthPhotoPath,
    ).resolve(createLocalImageConfiguration(context));
    if (stream.key != _stream?.key) {
      _stream?.removeListener(_listener);
      _stream = stream..addListener(_listener);
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _photo?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photo;
    // A foto carrega em milissegundos; até lá fica o fundo do card.
    if (photo == null) return const SizedBox.expand();
    return CustomPaint(
      painter: _PhotoMouthPainter(photo.image, widget.pose),
      size: Size.infinite,
    );
  }
}

// ---------------------------------------------------------------------------
// Pontos marcados à mão na foto (pixels do arquivo original, 3287x2191).
// Se trocar a foto, estes números precisam ser marcados de novo.
// ---------------------------------------------------------------------------

/// Linha entre os lábios, do canto esquerdo ao direito. É por ela que a
/// foto é "rasgada" em duas malhas: lábio de cima e lábio de baixo + queixo.
const _seam = [
  Offset(890, 1300),
  Offset(950, 1292),
  Offset(1000, 1284),
  Offset(1050, 1272),
  Offset(1100, 1258),
  Offset(1200, 1240),
  Offset(1300, 1232),
  Offset(1400, 1228),
  Offset(1500, 1226),
  Offset(1600, 1228),
  Offset(1700, 1232),
  Offset(1800, 1237),
  Offset(1900, 1243),
  Offset(2000, 1250),
  Offset(2100, 1260),
  Offset(2200, 1274),
  Offset(2290, 1296),
];

/// Meio da boca (entre os cantos) e meia largura dela. Todas as medidas da
/// deformação são frações de [_halfWidth], pra não depender da resolução.
const _centerX = 1590.0;
const _halfWidth = 700.0;

/// Pedaço quadrado da foto que aparece: das narinas ao queixo, com um pouco
/// de bochecha dos lados.
const _crop = Rect.fromLTWH(690, 390, 1800, 1800);

double _seamY(double x) {
  if (x <= _seam.first.dx) return _seam.first.dy;
  for (var i = 1; i < _seam.length; i++) {
    final b = _seam[i];
    if (x <= b.dx) {
      final a = _seam[i - 1];
      return a.dy + (b.dy - a.dy) * (x - a.dx) / (b.dx - a.dx);
    }
  }
  return _seam.last.dy;
}

final _seamCenterY = _seamY(_centerX);

/// Malha da língua: linhas do assoalho da boca até a raiz (passando pela
/// ponta), colunas de uma borda à outra.
const _tongueRows = 64;
const _tongueColumns = 48;

/// Distância da "câmera" até os dentes: dá a perspectiva — o que está no
/// fundo da boca encolhe em direção ao meio.
const _cameraDistance = 4.0 * _halfWidth;

double _sq(double x) => x * x;

/// Um milímetro em pixels da foto: a boca (de canto a canto, 2 *
/// [_halfWidth]) tem uns 50 mm.
const _mm = _halfWidth / 25;

/// Formato de um dente visto de frente, em milímetros (medidas médias de
/// dentes permanentes).
class _Tooth {
  final double width;
  final double length;

  /// Quanto a borda fica mais alta (nos de cima) ou mais baixa (nos de
  /// baixo) que a dos incisivos centrais: o lateral de cima é mais curto.
  final double shorter;

  /// Quanto a borda é translúcida (bem mais nos incisivos).
  final double translucent;

  /// Arredondamento dos cantos da borda, do lado do meio da boca e do
  /// lado de fora (fração da meia largura). O de fora é mais redondo.
  final double mesialRound;
  final double distalRound;

  /// Canino e pré-molar: altura da ponta (mm) — a borda sobe dos lados.
  final double cusp;

  const _Tooth(
    this.width,
    this.length, {
    this.shorter = 0,
    this.translucent = 1,
    this.mesialRound = 0.2,
    this.distalRound = 0.35,
    this.cusp = 0,
  });

  /// Até onde o dente vai (0 = colo, 1 = borda) na coluna [u] (-1 do lado
  /// do meio da boca, 1 do lado de fora).
  double end(double u) {
    final round = u < 0 ? mesialRound : distalRound;
    final t = ((u.abs() - (1 - round)) / round).clamp(0.0, 1.0);
    final corner = 1 - round * width / 2 / length * (1 - math.sqrt(1 - t * t));
    if (cusp == 0) return corner;
    // Ponta um pouco puxada pro lado do meio, como no canino.
    final d = (u + 0.1).abs() / 1.1;
    return math.min(corner, 1 - cusp / length * math.pow(d, 1.6));
  }
}

const _upperTeeth = [
  _Tooth(8.5, 10.5, mesialRound: 0.14, distalRound: 0.3),
  _Tooth(6.6, 9, shorter: 0.6, translucent: 0.9, mesialRound: 0.22, distalRound: 0.35),
  _Tooth(7.6, 10, shorter: 0.2, translucent: 0.5, mesialRound: 0.15, distalRound: 0.2, cusp: 1.3),
  _Tooth(7, 8.5, shorter: 0.6, translucent: 0.3, mesialRound: 0.15, distalRound: 0.2, cusp: 1),
  _Tooth(6.5, 7.5, shorter: 0.9, translucent: 0.2, mesialRound: 0.15, distalRound: 0.2, cusp: 0.9),
];

const _lowerTeeth = [
  _Tooth(5, 9, mesialRound: 0.12, distalRound: 0.15),
  _Tooth(5.5, 9.5, translucent: 0.9, mesialRound: 0.15, distalRound: 0.25),
  _Tooth(7, 11, translucent: 0.5, mesialRound: 0.15, distalRound: 0.2, cusp: 1.1),
  _Tooth(7, 8.5, shorter: 0.6, translucent: 0.3, mesialRound: 0.15, distalRound: 0.2, cusp: 0.9),
  _Tooth(7, 8, shorter: 0.8, translucent: 0.2, mesialRound: 0.15, distalRound: 0.2, cusp: 0.8),
];

/// Ponto da arcada (parábola z = -a·x², em pixels) a [s] pixels do meio,
/// medidos ao longo dela, e a normal pra fora (x, z).
(double, double, double, double) _arch(double s, double a) {
  double asinh(double y) => math.log(y + math.sqrt(y * y + 1));
  double length(double x) {
    final k = 2 * a * x;
    return (k * math.sqrt(1 + k * k) + asinh(k)) / (4 * a);
  }

  var x = s;
  for (var i = 0; i < 5; i++) {
    final k = 2 * a * x;
    x -= (length(x) - s) / math.sqrt(1 + k * k);
  }
  final k = 2 * a * x;
  final n = math.sqrt(1 + k * k);
  return (x, -a * x * x, k / n, 1 / n);
}

double _mix3(double body, double neck, double edge, double toNeck, double toEdge) {
  final b = body + (neck - body) * toNeck;
  return b + (edge - b) * toEdge;
}

double _smoothstep(double edge0, double edge1, double x) {
  final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Tudo que a pose muda na boca, já em pixels da foto.
class _Rig {
  final MouthPose pose;

  /// Quanto o lábio de cima sobe e o de baixo desce, no meio da boca.
  final double upperRaise;
  final double lowerDrop;
  final double lowerLift;

  /// Formato do vão: menor = mais "retangular" (sorriso, "I"); maior = mais
  /// redondo ("O", "U").
  final double roundness;

  /// Escala horizontal da boca: >1 estica (sorriso), <1 faz bico.
  final double widthScale;

  /// Lábios mais grossos (bico) ou mais finos (apertados, "M"/"P").
  final double thickness;

  /// Borda dos dentes de cima (fixa: é o crânio) e dos de baixo (vai com o
  /// queixo).
  final double upperTeethEdge;
  final double lowerTeethEdge;

  _Rig._({
    required this.pose,
    required this.upperRaise,
    required this.lowerDrop,
    required this.lowerLift,
    required this.roundness,
    required this.widthScale,
    required this.thickness,
    required this.upperTeethEdge,
    required this.lowerTeethEdge,
  });

  factory _Rig(MouthPose p) {
    // Abertura total entre os lábios. No "F"/"V" quem abre é só o lábio de
    // cima, pra mostrar os dentes encostados no de baixo.
    final lipGap = 0.62 * _halfWidth * p.lips * (1 - p.bite);
    // O lábio de cima mexe bem menos que o de baixo (que vai com o queixo);
    // no bico ele participa mais.
    // No sorriso ("I", "E", "S") o lábio de cima sobe mais e mostra os
    // dentes de cima, como numa boca de verdade.
    final upperShare = 0.24 + 0.12 * p.round + 0.36 * math.max(0.0, p.width - 0.6);
    // A borda dos incisivos de cima fica uns 1,5 mm abaixo da linha dos
    // lábios: no sorriso são eles que aparecem, não os de baixo.
    final upperTeethEdge = _seamCenterY + 1.5 * _mm;
    return _Rig._(
      pose: p,
      upperRaise: lipGap * upperShare + 0.10 * _halfWidth * p.bite,
      lowerDrop: lipGap * (1 - upperShare),
      // No "F"/"V" o lábio de baixo sobe um pouco e entra embaixo dos dentes.
      lowerLift: 0.03 * _halfWidth * p.bite,
      roundness: (0.5 + 0.15 * p.round - 0.15 * (p.width - 0.5)).clamp(0.35, 0.75),
      widthScale: (1 + 0.24 * (p.width - 0.5)) * (1 - 0.26 * p.round),
      thickness: 0.18 * p.round - 0.30 * p.press,
      upperTeethEdge: upperTeethEdge,
      lowerTeethEdge: upperTeethEdge + 4 + 0.48 * _halfWidth * p.jaw,
    );
  }

  /// Quanto um ponto acompanha a abertura dos lábios: 1 no meio da boca, 0
  /// nos cantos (a boca não rasga pros lados). [u] é a posição horizontal
  /// (-1 e 1 nos cantos) e [a] a distância até a linha dos lábios — longe
  /// dela (queixo) o movimento vale pra uma faixa mais larga, o queixo desce
  /// inteiro.
  double profile(double u, double a) {
    // 0.88: perto dos cantos os lábios continuam encostados (a comissura),
    // senão o vão vira uma fenda recortada de ponta a ponta.
    final reach = 0.88 * (1 + 1.2 * a);
    final k = 1 - (u / reach) * (u / reach);
    return k <= 0 ? 0 : math.pow(k, roundness).toDouble();
  }

  /// Onde o ponto (x, y) da foto vai parar nesta pose. [upper] diz de qual
  /// malha ele é — na linha dos lábios as duas se separam.
  Offset deform(double x, double y, {required bool upper}) {
    final seam = _seamY(x);
    final u = (x - _centerX) / _halfWidth;
    final a = (y - seam).abs() / _halfWidth;

    var dy = upper
        ? -upperRaise * profile(u, a) * (1 - _smoothstep(0.30, 0.85, a))
        // O queixo desce inteiro; já o lábio de baixo subindo no "F"/"V"
        // ([lowerLift]) é só o lábio, o queixo fica onde está.
        : lowerDrop * profile(u, a) -
              lowerLift * profile(u, a) * (1 - _smoothstep(0.2, 0.6, a));
    // Engrossar/afinar os lábios: estica ou encolhe em volta da linha deles.
    final lips =
        (1 - _smoothstep(0.35, 0.8, a)) * (1 - _smoothstep(0.95, 1.25, u.abs()));
    dy += thickness * (y - seam) * lips;

    final around =
        (1 - _smoothstep(0.35, 1.1, a)) * (1 - _smoothstep(1.0, 1.28, u.abs()));
    final dx = (widthScale - 1) * (x - _centerX) * around;
    return Offset(x + dx, y + dy);
  }
}

class _PhotoMouthPainter extends CustomPainter {
  final ui.Image photo;
  final MouthPose pose;

  _PhotoMouthPainter(this.photo, this.pose);

  static const _columns = 72;
  static const _rows = 28;

  static const _cavityDeep = Color(0xFF1C0406);
  static const _cavityNear = Color(0xFF5A1C22);
  static const _innerLip = Color(0xFF7E2A32);

  @override
  void paint(Canvas canvas, Size size) {
    final rig = _Rig(pose);

    // Preenche o widget (cover) com o recorte, centralizado na boca.
    final scale = math.max(size.width, size.height) / _crop.width;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-_crop.center.dx, -_crop.center.dy);

    final upperEdge = <Offset>[];
    final lowerEdge = <Offset>[];
    for (var i = 0; i <= _columns; i++) {
      final x = _crop.left + _crop.width * i / _columns;
      upperEdge.add(rig.deform(x, _seamY(x), upper: true));
      lowerEdge.add(rig.deform(x, _seamY(x), upper: false));
    }

    final open = rig.upperRaise + rig.lowerDrop > 1;
    if (open) _paintInside(canvas, rig, upperEdge, lowerEdge);

    final photoPaint = Paint()
      ..shader = ImageShader(
        photo,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
        filterQuality: FilterQuality.medium,
      );
    _drawMesh(canvas, rig, photoPaint, upper: false);
    if (pose.bite > 0.02) _paintBite(canvas, rig, upperEdge);
    _drawMesh(canvas, rig, photoPaint, upper: true);

    canvas.restore();
  }

  /// Uma das duas metades da foto como malha de triângulos: a textura é a
  /// posição original de cada ponto, a posição na tela é a deformada.
  void _drawMesh(Canvas canvas, _Rig rig, Paint paint, {required bool upper}) {
    final positions = <Offset>[];
    final texture = <Offset>[];
    final opening = ((rig.upperRaise + rig.lowerDrop) / 50).clamp(0.0, 1.0);
    for (var i = 0; i <= _columns; i++) {
      final x = _crop.left + _crop.width * i / _columns;
      final seam = _seamY(x);
      // Com a boca aberta, a borda de cada lábio pega a cor do lábio, não
      // a risca escura entre eles na foto (senão o vão ganha um contorno
      // preto de desenho). Fechada, nada muda: a risca é a da foto.
      final skip =
          14 * opening * rig.profile((x - _centerX) / _halfWidth, 0).clamp(0.0, 1.0);
      for (var j = 0; j <= _rows; j++) {
        final w = j / _rows;
        // Linhas mais juntas perto dos lábios, onde a deformação é maior.
        final y = upper
            ? seam - (seam - _crop.top) * math.pow(1 - w, 1.7)
            : seam + (_crop.bottom - seam) * math.pow(w, 1.7);
        final atSeam = upper ? j == _rows : j == 0;
        texture.add(atSeam ? Offset(x, upper ? y - skip : y + skip) : Offset(x, y));
        positions.add(rig.deform(x, y, upper: upper));
      }
    }
    final indices = <int>[];
    for (var i = 0; i < _columns; i++) {
      for (var j = 0; j < _rows; j++) {
        final a = i * (_rows + 1) + j;
        final b = a + _rows + 1;
        indices.addAll([a, b, a + 1, a + 1, b, b + 1]);
      }
    }
    final vertices = ui.Vertices(
      ui.VertexMode.triangles,
      positions,
      textureCoordinates: texture,
      indices: indices,
    );
    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
    vertices.dispose();
  }

  /// Interior da boca, desenhado antes das malhas: só aparece no vão entre
  /// os lábios.
  void _paintInside(
    Canvas canvas,
    _Rig rig,
    List<Offset> upperEdge,
    List<Offset> lowerEdge,
  ) {
    final top = _seamCenterY - rig.upperRaise;
    final bottom = _seamCenterY + rig.lowerDrop;
    final halfOpen = _halfWidth * rig.widthScale;
    final center = Offset(_centerX, (top + bottom) / 2);
    final area = Rect.fromLTRB(
      _centerX - halfOpen * 1.1,
      top - 120,
      _centerX + halfOpen * 1.1,
      bottom + 120,
    );

    canvas.drawRect(
      area,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          halfOpen,
          [_cavityDeep, _cavityNear],
          [0.25, 1],
        ),
    );

    _paintTongue(canvas, rig, center, halfOpen);
    // Sombra que os dentes e o lábio de cima fazem na língua logo abaixo.
    canvas.drawRect(
      Rect.fromLTRB(area.left, rig.upperTeethEdge - 20, area.right, rig.upperTeethEdge + 50),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    _paintTeeth(canvas, edge: rig.lowerTeethEdge, upper: false, vanish: center, lip: lowerEdge);
    _paintTeeth(canvas, edge: rig.upperTeethEdge, upper: true, vanish: center, lip: upperEdge);

    // Fundo e cantos da boca mais escuros: a luz entra pela frente.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(halfOpen, math.max(40, (bottom - top) / 2 + 40));
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          1,
          [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
          [0.45, 1],
        ),
    );
    canvas.restore();

    // Parte de dentro dos lábios (mais escura e úmida) e a sombra que o
    // lábio de cima faz nos dentes. Metade do traço fica embaixo da foto.
    // Faixa larga e borrada: um traço fino vira um contorno de adesivo.
    for (final edge in [upperEdge, lowerEdge]) {
      canvas.drawPath(
        Path()..addPolygon(edge, false),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..color = _innerLip.withValues(alpha: 0.8)
          ..strokeWidth = 46
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }
    canvas.drawPath(
      Path()..addPolygon([for (final p in upperEdge) p.translate(0, 20)], false),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black.withValues(alpha: 0.22)
        ..strokeWidth = 34
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
  }

  /// Uma fileira de dentes (incisivos central e lateral, canino e dois
  /// pré-molares de cada lado), cada um uma malhinha 3D — retângulos com
  /// degradê pareciam "teclas" de desenho ao lado da foto. Os dentes ficam
  /// numa arcada em parábola (os de trás recuam, encolhem na perspectiva e
  /// pegam menos luz), com o formato e o tamanho de dentes de verdade e a
  /// luz calculada ponto a ponto: a face da frente é abaulada (escurece nos
  /// lados, onde um dente encosta no outro), o esmalte tem brilho, a borda
  /// é translúcida (deixa ver o escuro da boca) e o colo, perto da gengiva,
  /// é mais amarelado. [lip] é a borda do lábio que cobre a fileira: o
  /// dente escurece logo abaixo (ou acima) dela, na sombra do lábio.
  void _paintTeeth(
    Canvas canvas, {
    required double edge,
    required bool upper,
    required Offset vanish,
    required List<Offset> lip,
    double opacity = 1,
  }) {
    final teeth = upper ? _upperTeeth : _lowerTeeth;
    // Os de baixo ficam atrás dos de cima (a borda de cima cobre a de
    // baixo uns 2,5 mm quando os dentes se encostam, como no "S").
    final front = upper ? 0.0 : -2.5 * _mm;
    final incisal = upper ? edge : edge - 2.5 * _mm;
    final curve = upper ? 0.0011 : 0.0013;
    final texture = Paint()
      ..shader = ImageShader(
        _enamelTexture(),
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
        filterQuality: FilterQuality.medium,
      );

    double lipY(double x) {
      if (x <= lip.first.dx) return lip.first.dy;
      for (var i = 1; i < lip.length; i++) {
        if (x <= lip[i].dx) {
          final a = lip[i - 1], b = lip[i];
          return a.dy + (b.dy - a.dy) * (x - a.dx) / (b.dx - a.dx);
        }
      }
      return lip.last.dy;
    }

    // Gengiva atrás da fileira: entre os dentes, perto do colo, aparece
    // ela (rosa) e não o escuro da boca.
    final gumFrom = incisal + (upper ? -0.4 : 0.4) * 10 * _mm;
    canvas.drawRect(
      Rect.fromLTRB(_centerX - 900, math.min(gumFrom, gumFrom + (upper ? -400 : 400)),
          _centerX + 900, math.max(gumFrom, gumFrom + (upper ? -400 : 400))),
      Paint()
        ..color = const Color(0xFF8E3E46).withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );

    // Começo de cada dente na arcada, a partir do meio.
    final starts = <double>[];
    var s = 0.0;
    for (final t in teeth) {
      starts.add(s);
      s += t.width * _mm + 0.5; // encostados: fresta mostraria o preto da boca
    }

    const columns = 22;
    const rows = 16;
    const lx = 0.12 / 1.12, ly = -0.5 / 1.12, lz = 1.0 / 1.12;
    final hLen = math.sqrt(lx * lx + ly * ly + (lz + 1) * (lz + 1));
    final hx = lx / hLen, hy = ly / hLen, hz = (lz + 1) / hLen;

    for (final side in const [-1.0, 1.0]) {
      // Do fundo pra frente: o da frente cobre a beirada do de trás.
      for (var i = teeth.length - 1; i >= 0; i--) {
        final t = teeth[i];
        final halfWidth = t.width * _mm / 2;
        final length = t.length * _mm;
        final center = starts[i] + halfWidth;
        final toothEdge = incisal + (upper ? -1 : 1) * t.shorter * _mm;
        final positions = <Offset>[];
        final colors = <Color>[];
        final coords = <Offset>[];
        for (var c = 0; c <= columns; c++) {
          // u: -1 do lado do meio da boca, 1 do lado de fora.
          final u = -1 + 2 * c / columns;
          final end = t.end(u);
          for (var r = 0; r <= rows; r++) {
            // v: 0 no colo (escondido no lábio), 1 na borda que corta.
            final v = end * r / rows;
            // Coroa mais estreita no colo.
            final narrow = 0.8 + 0.2 * _smoothstep(0.0, 0.55, v);
            final (ax, az, anx, anz) = _arch(center + u * halfWidth * narrow, curve);
            // Dente inclinado pra frente: a borda mais à frente que o colo.
            final z = front + az - (1 - v) * 0.22 * length;
            final x = _centerX + side * ax;
            final y = upper ? toothEdge - length * (1 - v) : toothEdge + length * (1 - v);
            final scale = _cameraDistance / (_cameraDistance - z);
            positions.add(Offset(vanish.dx + (x - vanish.dx) * scale, vanish.dy + (y - vanish.dy) * scale));
            coords.add(Offset(128 + 120 * u, 256 * v));

            // Normal: a da arcada, girada pela curva da face (de lado a
            // lado e de cima a baixo) e pela inclinação do dente.
            final phi = 0.4 * u;
            final cosP = math.cos(phi), sinP = math.sin(phi);
            var nx = side * (anx * cosP + anz * sinP);
            var nz = -anx * sinP + anz * cosP;
            var ny = upper ? -0.15 + 0.35 * (v - 0.6) : 0.15 - 0.35 * (v - 0.6);
            final nLen = math.sqrt(nx * nx + ny * ny + nz * nz);
            nx /= nLen;
            ny /= nLen;
            nz /= nLen;
            final diffuse = ((nx * lx + ny * ly + nz * lz + 0.3) / 1.3).clamp(0.0, 1.0);
            // O brilho do esmalte é uma faixinha vertical: o dente é bem
            // mais curvo de lado a lado do que de cima a baixo. Por isso a
            // normal do brilho gira mais com u e quase nada com v (com a
            // mesma normal da luz difusa, saía uma faixa horizontal de
            // metal).
            final phiS = 1.3 * u;
            final cosS = math.cos(phiS), sinS = math.sin(phiS);
            final sx = side * (anx * cosS + anz * sinS);
            final sz = -anx * sinS + anz * cosS;
            final sy = upper ? -0.24 + 0.12 * (v - 0.6) : 0.1;
            final sLen = math.sqrt(sx * sx + sy * sy + sz * sz);
            final nh = math.max(0.0, (sx * hx + sy * hy + sz * hz) / sLen);
            final spec = 0.26 * math.pow(nh, 60) + 0.05 * math.pow(nh, 12);
            final depth = math.pow((1 + z / (1.6 * _halfWidth)).clamp(0.2, 1.0), 1.2).toDouble();
            final contact = 1 - 0.25 * _smoothstep(0.82, 1.0, u.abs());
            // Sombra do lábio: só uma faixa estreita junto dele — o pedaço
            // de dente que aparece é pequeno, uma sombra larga o deixa todo
            // cinza.
            final underLip = upper ? y - lipY(x) : lipY(x) - y;
            final lipShadow = 0.55 + 0.45 * _smoothstep(0.0, 35.0, underLip);
            final lit = depth * contact * lipShadow;

            // Esmalte marfim; colo mais amarelado; borda translúcida
            // (azulada e deixando passar o fundo).
            final neck = 1 - _smoothstep(0.15, 0.6, v);
            final clear = _smoothstep(end - 0.16, end, v) * t.translucent;
            double tone(double body, double neckTone, double edgeTone) =>
                _mix3(body, neckTone, edgeTone, neck, clear);
            final shade = (0.66 + 0.5 * diffuse) * lit;
            int channel(double base, double tint) =>
                (255 * (base * shade + spec * lit * tint)).round().clamp(0, 255);
            colors.add(
              Color.fromARGB(
                (255 * opacity * (1 - 0.12 * clear)).round(),
                channel(tone(0.95, 0.90, 0.74), 1),
                channel(tone(0.92, 0.82, 0.78), 1),
                channel(tone(0.86, 0.66, 0.84), 1),
              ),
            );
          }
        }
        final indices = <int>[];
        for (var c = 0; c < columns; c++) {
          for (var r = 0; r < rows; r++) {
            final a = c * (rows + 1) + r;
            final b = a + rows + 1;
            indices.addAll([a, b, a + 1, a + 1, b, b + 1]);
          }
        }
        final vertices = ui.Vertices(
          ui.VertexMode.triangles,
          positions,
          colors: colors,
          textureCoordinates: coords,
          indices: indices,
        );
        canvas.drawVertices(vertices, BlendMode.modulate, texture);
        vertices.dispose();
      }
    }
  }

  static ui.Image? _enamelTextureCache;

  /// Textura do esmalte (256x256, multiplicada pela cor iluminada): as
  /// linhas horizontais bem fracas do crescimento do esmalte (periquimácias)
  /// e manchinhas mais brancas e mais opacas, como em dente de verdade.
  static ui.Image _enamelTexture() {
    final cached = _enamelTextureCache;
    if (cached != null) return cached;
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    const n = 256.0;
    c.drawRect(const Rect.fromLTWH(0, 0, n, n), Paint()..color = const Color(0xFFF2F2F2));
    final line = Paint()
      ..color = const Color(0xFFD9D9D9).withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    for (var y = 3.0; y < n; y += 7) {
      c.drawLine(Offset(0, y), Offset(n, y + 2), line);
    }
    final random = math.Random(3);
    final spot = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    for (var i = 0; i < 40; i++) {
      spot.color = (random.nextBool() ? const Color(0xFFFFFFFF) : const Color(0xFFE2DED8))
          .withValues(alpha: 0.4);
      c.drawCircle(
        Offset(random.nextDouble() * n, random.nextDouble() * n),
        6 + 14 * random.nextDouble(),
        spot,
      );
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(n.toInt(), n.toInt());
    picture.dispose();
    return _enamelTextureCache = image;
  }

  /// A língua é uma superfície em 3D (simples) vista de frente, com
  /// perspectiva e luz calculada ponto a ponto — uma forma chapada com
  /// degradê não fica no nível da foto. O corte do meio da língua (do
  /// assoalho da boca, por baixo, até a ponta e daí até a raiz, no fundo) é
  /// uma curva por 6 pontos que a pose move; a largura vem dobrada pra
  /// baixo nas bordas (a língua é abaulada) com o sulco no meio do dorso.
  /// Assim a mesma superfície mostra o dorso com papilas quando está
  /// deitada ("A") e o lado de baixo, liso, arroxeado, com o freio e as
  /// veias, quando a ponta sobe ("L", "T").
  void _paintTongue(Canvas canvas, _Rig rig, Offset vanish, double halfOpen) {
    final p = rig.pose;
    const h = _halfWidth;
    final ute = rig.upperTeethEdge;
    final lte = rig.lowerTeethEdge;
    double mix(double a, double b, double t) => a + (b - a) * t;

    // Deitada, a língua acompanha o queixo (posições a partir dos dentes de
    // baixo); erguida, encosta no céu da boca, que é fixo (a partir dos de
    // cima). Um articulador puxa um pouco os vizinhos: a ponta subindo leva
    // junto a frente do dorso, e o dorso da frente e o de trás se puxam.
    final tip = p.tongueTip;
    final frontLift = math.max(p.tongueFront, math.max(0.35 * p.tongueBack, 0.3 * tip));
    final backLift = math.max(p.tongueBack, 0.35 * p.tongueFront);
    final floor = (lte + 0.42 * h, -0.17 * h, 0.30 * h);
    // Ponta: atrás dos dentes de baixo, ou nos alvéolos (atrás dos de cima).
    final tipY = mix(lte - 0.05 * h, ute - 0.10 * h, tip);
    final control = <(double, double, double)>[
      floor,
      (mix(lte + 0.18 * h, (floor.$1 + tipY) / 2, tip), mix(-0.14 * h, -0.10 * h, tip), mix(0.5, 0.42, tip) * h),
      (tipY, mix(-0.10 * h, -0.16 * h, tip), mix(0.62, mix(0.50, 0.34, p.tongueNarrow), tip) * h),
      // Deitada, o dorso fica acima da borda dos dentes de baixo, e não
      // desce tudo que o queixo desce: no "A" é ele que enche o fundo do
      // vão.
      (mix(lte - (0.15 + 0.12 * p.jaw) * h, ute - 0.27 * h, frontLift), -0.42 * h, 0.62 * h),
      (mix(lte - (0.11 + 0.12 * p.jaw) * h, ute - 0.22 * h, backLift), -0.80 * h, 0.56 * h),
      (lte + 0.10 * h, -1.15 * h, 0.44 * h),
    ];
    const knots = [-1.0, -0.5, 0.0, 0.35, 0.7, 1.0];

    // Curva do meio (Catmull-Rom pelos pontos de controle).
    (double, double, double) along(double t) {
      var j = 0;
      while (j < knots.length - 2 && t > knots[j + 1]) {
        j++;
      }
      final u = ((t - knots[j]) / (knots[j + 1] - knots[j])).clamp(0.0, 1.0);
      final a = control[math.max(0, j - 1)];
      final b = control[j];
      final c = control[j + 1];
      final d = control[math.min(control.length - 1, j + 2)];
      double cr(double p0, double p1, double p2, double p3) =>
          0.5 *
          (2 * p1 +
              (-p0 + p2) * u +
              (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u +
              (-p0 + 3 * p1 - 3 * p2 + p3) * u * u * u);
      return (cr(a.$1, b.$1, c.$1, d.$1), cr(a.$2, b.$2, c.$2, d.$2), cr(a.$3, b.$3, c.$3, d.$3));
    }

    // Uma linha da malha bem na ponta (t = 0), que é onde o dorso vira o
    // lado de baixo: as duas texturas se encontram ali.
    const half = _tongueRows ~/ 2;
    final ts = [
      for (var i = 0; i <= _tongueRows; i++) i < half ? -1 + i / half : (i - half) / half,
    ];
    final mid = [for (final t in ts) along(t)];
    // Distância de cada linha até a ponta, medida na superfície.
    final arc = List<double>.filled(ts.length, 0);
    for (var i = half + 1; i < ts.length; i++) {
      arc[i] = arc[i - 1] + math.sqrt(_sq(mid[i].$1 - mid[i - 1].$1) + _sq(mid[i].$2 - mid[i - 1].$2));
    }
    for (var i = half - 1; i >= 0; i--) {
      arc[i] = arc[i + 1] - math.sqrt(_sq(mid[i].$1 - mid[i + 1].$1) + _sq(mid[i].$2 - mid[i + 1].$2));
    }

    // Luz de frente e um pouco de cima, como na foto.
    const light = (0.12, -0.5, 1.0);
    final lightLen = math.sqrt(_sq(light.$1) + _sq(light.$2) + _sq(light.$3));
    final lx = light.$1 / lightLen, ly = light.$2 / lightLen, lz = light.$3 / lightLen;
    final hLen = math.sqrt(_sq(lx) + _sq(ly) + _sq(lz + 1));
    final hx = lx / hLen, hy = ly / hLen, hz = (lz + 1) / hLen;
    // Pouca abertura, pouca luz lá dentro — mas sem apagar a língua, que é
    // o que a criança precisa ver no "N", "NH", "LH".
    final lightIn = ((rig.upperRaise + rig.lowerDrop) / (0.4 * h)).clamp(0.65, 1.0);
    // Ponta arredondada (vista de cima ou de frente); no "L" é fina.
    final tipRound = 0.32 * h;
    final tipMin = 0.55 - 0.3 * p.tongueNarrow;
    // Bordas mais caídas no "L" (o ar passa pelos lados).
    final dome = 0.28 + 0.3 * p.tongueNarrow * tip;
    const grooveWidth = 0.17;
    const frenulumWidth = 0.07;

    final positions = <Offset>[];
    final colors = <Color>[];
    final texture = <Offset>[];
    for (var i = 0; i < ts.length; i++) {
      final (y0, z0, w0) = mid[i];
      // Normal da curva do meio, pra fora da língua (pra cima no dorso, pra
      // frente no lado de baixo).
      final a = mid[math.max(0, i - 1)];
      final b = mid[math.min(ts.length - 1, i + 1)];
      final dy = b.$1 - a.$1, dz = b.$2 - a.$2;
      final len = math.max(1e-6, math.sqrt(dy * dy + dz * dz));
      final ny = dz / len, nz = -dy / len;

      final k = 1 - (arc[i].abs() / tipRound).clamp(0.0, 1.0);
      final w = w0 * (tipMin + (1 - tipMin) * math.sqrt(1 - k * k));
      final ventral = _smoothstep(0.02, -0.12, ts[i]);
      final groove = 0.014 * h * _smoothstep(0.04, 0.3, ts[i]);
      final frenulum = 0.014 * h * _smoothstep(-0.2, -0.65, ts[i]);
      final v = arc[i] >= 0
          ? 384 * (arc[i] / arc.last).clamp(0.0, 1.0)
          : 384 + 127 * (arc[i] / arc.first).clamp(0.0, 1.0);

      for (var j = 0; j <= _tongueColumns; j++) {
        final s = -1 + 2 * j / _tongueColumns;
        final g = groove * math.exp(-_sq(s / grooveWidth));
        // O freio: uma dobra saltada no meio do lado de baixo.
        final f = frenulum * math.exp(-_sq(s / frenulumWidth));
        final r = w * (dome * s * s + 0.22 * math.pow(s, 6)) + g - f;
        final slope = 2 * dome * s +
            1.32 * math.pow(s, 5) -
            g / w * 2 * s / _sq(grooveWidth) +
            f / w * 2 * s / _sq(frenulumWidth);
        final x = _centerX + s * w;
        final y = y0 - ny * r;
        final z = z0 - nz * r;
        final scale = _cameraDistance / (_cameraDistance - z);
        positions.add(Offset(vanish.dx + (x - vanish.dx) * scale, vanish.dy + (y - vanish.dy) * scale));
        // Textura pela largura real (não por fração da largura): perto da
        // ponta, onde a língua afina, as papilas não se espremem.
        texture.add(Offset(256 + 255 * s * w / (0.62 * h), v));

        final nLen = math.sqrt(slope * slope + 1);
        final nx = slope / nLen, nyy = ny / nLen, nzz = nz / nLen;
        // Luz "enrolada" (passa um pouco do terminador): tecido mole e
        // úmido não tem sombra dura.
        final diffuse = ((nx * lx + nyy * ly + nzz * lz + 0.4) / 1.4).clamp(0.0, 1.0);
        final nh = math.max(0.0, nx * hx + nyy * hy + nzz * hz);
        // Brilho: o dorso (papilas) é aveludado, brilho largo e fraco; o
        // lado de baixo é liso e brilha mais, mais concentrado.
        final spec = mix(
          0.22 * math.pow(nh, 26) + 0.10 * math.pow(nh, 8),
          0.22 * math.pow(nh, 40) + 0.05 * math.pow(nh, 10),
          ventral,
        );
        // Fundo da boca recebe menos luz; acima da borda dos dentes de
        // cima, a sombra deles.
        final occlusion = math.pow((1 + z / (1.3 * h)).clamp(0.08, 1.0), 1.4).toDouble();
        final teethShadow = 0.45 + 0.55 * _smoothstep(ute - 0.12 * h, ute + 0.05 * h, y);
        // Com a ponta erguida, o dorso atrás dela fica na sombra da ponta.
        final tipShadow = 1 - 0.5 * tip * _smoothstep(0.0, 0.15, ts[i]);
        final lit = occlusion * teethShadow * tipShadow * lightIn;
        final base = (
          mix(0.88, 0.68, ventral),
          mix(0.50, 0.30, ventral),
          mix(0.52, 0.40, ventral),
        );
        final shade = (0.15 + 0.95 * diffuse) * lit / 0.92;
        // As bordas (perto das bochechas) somem na penumbra da boca: vão
        // pra cor do fundo da boca, não pro preto — senão viram manchas
        // mais escuras que a própria boca.
        // A cor do fundo é a do degradê pintado atrás, no mesmo ponto.
        final fade = _smoothstep(0.5, 0.97, s.abs());
        final screen = positions.last;
        final cavity = Color.lerp(
          _cavityDeep,
          _cavityNear,
          ((((screen - vanish).distance / halfOpen) - 0.25) / 0.75).clamp(0.0, 1.0),
        )!;
        int channel(double c, double tint, double back) =>
            (255 * mix(c * shade + spec * lit * tint, back, fade)).round().clamp(0, 255);
        colors.add(
          Color.fromARGB(
            255,
            channel(base.$1, 1, cavity.r),
            channel(base.$2, 0.9, cavity.g),
            channel(base.$3, 0.92, cavity.b),
          ),
        );
      }
    }

    // Dorso primeiro (do fundo pra ponta), depois o lado de baixo — que,
    // com a ponta erguida, fica na frente do dorso.
    const stride = _tongueColumns + 1;
    List<int> band(int from, int to) => [
      for (var i = from; i >= to; i--)
        for (var j = 0; j < _tongueColumns; j++) ...[
          i * stride + j,
          (i + 1) * stride + j,
          i * stride + j + 1,
          i * stride + j + 1,
          (i + 1) * stride + j,
          (i + 1) * stride + j + 1,
        ],
    ];
    final paint = Paint()
      ..shader = ImageShader(
        _tongueTexture(),
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
        filterQuality: FilterQuality.medium,
      );
    for (final indices in [band(ts.length - 2, half), band(half - 1, 0)]) {
      final vertices = ui.Vertices(
        ui.VertexMode.triangles,
        positions,
        colors: colors,
        textureCoordinates: texture,
        indices: indices,
      );
      canvas.drawVertices(vertices, BlendMode.modulate, paint);
      vertices.dispose();
    }
  }

  static ui.Image? _tongueTextureCache;

  /// Textura da língua (512x512, multiplicada pela cor iluminada). Em cima
  /// (v 0–384, da ponta pra raiz) o dorso: pontinhos claros das papilas
  /// filiformes, que dão o aspecto aveludado, e as fungiformes, pontos
  /// avermelhados maiores, mais na ponta e nas bordas. Embaixo (v 384–512,
  /// da ponta pro assoalho) o lado de baixo: liso, com as duas veias
  /// azuladas e o freio no meio.
  static ui.Image _tongueTexture() {
    final cached = _tongueTextureCache;
    if (cached != null) return cached;
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    const n = 512.0;
    c.drawRect(const Rect.fromLTWH(0, 0, n, 384), Paint()..color = const Color(0xFFEAE2E2));
    final random = math.Random(7);
    final dot = Paint();
    for (var i = 0; i < 9000; i++) {
      final light = random.nextDouble() < 0.7;
      dot.color = (light ? const Color(0xFFFFFAFA) : const Color(0xFFD6CACB))
          .withValues(alpha: 0.25 + 0.3 * random.nextDouble());
      c.drawCircle(
        Offset(random.nextDouble() * n, random.nextDouble() * 384),
        0.8 + random.nextDouble(),
        dot,
      );
    }
    final fungiform = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    for (var i = 0; i < 900; i++) {
      final u = random.nextDouble();
      final v = random.nextDouble();
      // Mais perto da ponta (v pequeno) e das bordas (u perto de 0 ou 1).
      final edge = (u - 0.5).abs() * 2;
      if (random.nextDouble() > 0.25 + 0.75 * math.max(1 - v * 2.5, edge * edge)) continue;
      fungiform.color = const Color(0xFFE39CA4).withValues(alpha: 0.55 + 0.3 * random.nextDouble());
      c.drawCircle(Offset(u * n, v * 384), 1.6 + 1.6 * random.nextDouble(), fungiform);
    }
    c.drawRect(const Rect.fromLTWH(0, 384, n, 128), Paint()..color = const Color(0xFFF3EDEE));
    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..color = const Color(0xFFC2B4D8).withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (final side in const [-1.0, 1.0]) {
      final x = n / 2 + side * 0.15 * n;
      c.drawPath(
        Path()
          ..moveTo(x + side * 6, 425)
          ..cubicTo(x - side * 8, 450, x + side * 10, 480, x - side * 4, 512),
        vein,
      );
    }
    c.drawLine(
      const Offset(n / 2, 440),
      const Offset(n / 2, 512),
      Paint()
        ..strokeWidth = 12
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(n.toInt(), n.toInt());
    picture.dispose();
    return _tongueTextureCache = image;
  }

  /// "F"/"V": os dentes de cima por cima do lábio de baixo, com a sombra
  /// que fazem nele. Desenhado entre as duas malhas.
  void _paintBite(Canvas canvas, _Rig rig, List<Offset> upperEdge) {
    final bite = pose.bite;
    final teethEdge = rig.upperTeethEdge + 0.035 * _halfWidth * bite;
    final topAtCenter = _seamCenterY - rig.upperRaise;
    final lower = [
      for (final e in upperEdge)
        Offset(
          e.dx,
          e.dy +
              (teethEdge - topAtCenter) *
                  math.sqrt(rig.profile((e.dx - _centerX) / _halfWidth, 0)),
        ),
    ];
    final region = Path()
      ..addPolygon([...upperEdge, ...lower.reversed], true);

    // Sombra só embaixo dos dentes: fora da boca a linha coincide com a dos
    // lábios e riscaria o rosto de lado a lado.
    final shadowLine = [
      for (final p in lower)
        if (rig.profile((p.dx - _centerX) / _halfWidth, 0) > 0.05) p,
    ];
    canvas.drawPath(
      Path()..addPolygon(shadowLine, false),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black.withValues(alpha: 0.3 * bite)
        ..strokeWidth = 30
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.save();
    canvas.clipPath(region);
    _paintTeeth(
      canvas,
      edge: teethEdge,
      upper: true,
      vanish: Offset(_centerX, _seamCenterY + (rig.lowerDrop - rig.upperRaise) / 2),
      lip: upperEdge,
      opacity: bite,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PhotoMouthPainter oldDelegate) =>
      oldDelegate.pose != pose || oldDelegate.photo != photo;
}
