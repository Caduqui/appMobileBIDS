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
    final upperShare = 0.24 + 0.12 * p.round;
    final upperTeethEdge = _seamCenterY + 0.02 * _halfWidth;
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
  static const _toothEdge = Color(0xFFE6DFD2);
  static const _toothRoot = Color(0xFFA89A89);
  static const _toothFar = Color(0xFF5E4E46);
  static const _tongueLight = Color(0xFFD46F78);
  static const _tongueDark = Color(0xFF8C3440);
  static const _tongueUnder = Color(0xFFA2485A);

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

    _paintTongue(canvas, rig);
    _paintTeeth(canvas, edge: rig.lowerTeethEdge, upper: false);
    _paintTeeth(canvas, edge: rig.upperTeethEdge, upper: true);

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
          ..color = _innerLip.withValues(alpha: 0.9)
          ..strokeWidth = 60
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

  /// Uma fileira de dentes, do meio pros lados. Os de cima têm os dois da
  /// frente maiores; os do fundo ficam mais escuros e mais curtos (a
  /// arcada faz curva).
  void _paintTeeth(
    Canvas canvas, {
    required double edge,
    required bool upper,
    double opacity = 1,
  }) {
    const upperWidths = [205.0, 160.0, 135.0, 105.0, 85.0, 70.0];
    const lowerWidths = [130.0, 135.0, 140.0, 115.0, 90.0, 75.0];
    final widths = upper ? upperWidths : lowerWidths;
    const gap = 5.0;
    const height = 380.0;
    // Da borda pra raiz, o dente escurece (sombra do lábio/gengiva) ao
    // longo de [fade] pixels — o resto fica escondido atrás do lábio.
    const fade = 190.0;

    for (final side in const [-1.0, 1.0]) {
      var x = gap / 2;
      for (var i = 0; i < widths.length; i++) {
        final w = widths[i];
        final u = (x + w / 2) / _halfWidth;
        final curve = 0.07 * _halfWidth * u * u;
        final toothEdge = upper ? edge - curve : edge + curve;
        final left = _centerX + side * (side < 0 ? x + w : x);
        final rect = upper
            ? Rect.fromLTRB(left, toothEdge - height, left + w, toothEdge)
            : Rect.fromLTRB(left, toothEdge, left + w, toothEdge + height);
        // Os do fundo da arcada pegam menos luz.
        final far = (i * 0.2).clamp(0.0, 0.9);
        final tip = Color.lerp(_toothEdge, _toothFar, far)!;
        final root = Color.lerp(_toothRoot, _toothFar, far)!;
        // Canto pouco arredondado: muito redondo vira fileira de "teclas"
        // com um "v" escuro entre cada dente.
        final radius = Radius.circular(w * 0.14);
        final towardRoot = upper ? -fade : fade;
        canvas.drawRRect(
          upper
              ? RRect.fromRectAndCorners(rect, bottomLeft: radius, bottomRight: radius)
              : RRect.fromRectAndCorners(rect, topLeft: radius, topRight: radius),
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, toothEdge + towardRoot),
              Offset(0, toothEdge),
              [
                root.withValues(alpha: opacity),
                tip.withValues(alpha: opacity),
                // Borda do dente é meio translúcida, puxa pro cinza.
                Color.lerp(tip, const Color(0xFFB9BCC2), 0.45)!.withValues(alpha: opacity),
              ],
              const [0, 0.82, 1],
            )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        // Sombra de um lado de cada dente: dá volume e marca a divisão
        // entre eles sem um risco preto.
        canvas.drawRect(
          Rect.fromLTRB(
            side < 0 ? rect.left : rect.right - w * 0.22,
            rect.top,
            side < 0 ? rect.left + w * 0.22 : rect.right,
            rect.bottom,
          ),
          Paint()
            ..color = const Color(0xFF6D5D52).withValues(alpha: 0.22 * opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
        x += w + gap;
      }
    }
  }

  void _paintTongue(Canvas canvas, _Rig rig) {
    final p = rig.pose;
    // Deitada atrás dos dentes de baixo; a ponta sobe até atrás dos dentes
    // de cima ("L", "N", "D", "T"); o fundo sobe num morro largo ("C", "G").
    final restTop = rig.lowerTeethEdge - 0.14 * _halfWidth;
    final tipTop = rig.upperTeethEdge - 0.01 * _halfWidth;
    final backTop = rig.upperTeethEdge + 0.06 * _halfWidth;
    final top =
        restTop + (tipTop - restTop) * p.tongueTip + (backTop - restTop) * p.tongueBack;
    // Largura na base e na ponta: com a ponta erguida a língua afina em
    // cima (vira um "dedo" largo); deitada ou com o fundo erguido, é um
    // morro largo.
    final base = _halfWidth * (0.62 + 0.1 * p.tongueBack - 0.14 * p.tongueTip);
    final tip = base * (0.66 + 0.12 * p.tongueTip);
    final drop = _halfWidth * (0.3 + 0.1 * p.tongueTip);
    final bottom = top + _halfWidth;

    final tongue = Path()
      ..moveTo(_centerX - base, bottom)
      ..cubicTo(
        _centerX - base, top + drop,
        _centerX - tip, top + drop * 0.35,
        _centerX - tip * 0.55, top + drop * 0.06,
      )
      ..quadraticBezierTo(_centerX, top - drop * 0.04, _centerX + tip * 0.55, top + drop * 0.06)
      ..cubicTo(
        _centerX + tip, top + drop * 0.35,
        _centerX + base, top + drop,
        _centerX + base, bottom,
      )
      ..close();

    // Ponta erguida: vemos o lado de baixo, mais arroxeado. Fundo erguido:
    // mais longe da luz, mais escuro.
    final light = Color.lerp(
      Color.lerp(_tongueLight, _tongueUnder, p.tongueTip)!,
      _tongueDark,
      0.35 * p.tongueBack,
    )!;
    canvas.drawPath(
      tongue,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, top),
          Offset(0, top + _halfWidth * 0.5),
          [light, _tongueDark],
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Lados da língua mais escuros: ela é arredondada, não chapada.
    canvas.save();
    canvas.clipPath(tongue);
    canvas.drawRect(
      Rect.fromLTRB(_centerX - base, top - 20, _centerX + base, bottom),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(_centerX - base, 0),
          Offset(_centerX + base, 0),
          [
            Colors.black.withValues(alpha: 0.45),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.45),
          ],
          const [0, 0.35, 0.65, 1],
        ),
    );
    canvas.restore();
    // Sulco do meio (ou o freio, quando a ponta está erguida) e um brilho
    // de língua molhada.
    canvas.drawLine(
      Offset(_centerX, top + 30),
      Offset(_centerX, top + _halfWidth * 0.5),
      Paint()
        ..color = _tongueDark.withValues(alpha: 0.5 + 0.3 * p.tongueTip)
        ..strokeWidth = 10 + 8 * p.tongueTip
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(_centerX - tip * 0.2, top + 40),
        width: tip * 0.6,
        height: 30,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
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
    _paintTeeth(canvas, edge: teethEdge, upper: true, opacity: bite);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PhotoMouthPainter oldDelegate) =>
      oldDelegate.pose != pose || oldDelegate.photo != photo;
}
