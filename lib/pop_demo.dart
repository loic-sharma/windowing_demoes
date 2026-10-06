// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:material_ui/material_ui.dart';

class _MainWindowDelegate with WindowControllerDelegate {
  @override
  void onWindowDestroyed() {
    super.onWindowDestroyed();
    ServicesBinding.instance.exitApplication(AppExitType.required);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = WindowController(
    size: const Size(960, 640),
    title: 'Flutter Windowing',
    delegate: _MainWindowDelegate(),
  );

  runWidget(
    Window(
      controller: controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          colorSchemeSeed: const Color(0xFF6C5CE7),
        ),
        home: MainWindow(controller: controller),
      ),
    ),
  );
}

class MainWindow extends StatefulWidget {
  const MainWindow({super.key, required this.controller});

  final WindowController controller;

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow>
    with SingleTickerProviderStateMixin {
  final GlobalKey<PopWindowContentState> _popKey =
      GlobalKey<PopWindowContentState>();

  WindowController? _child;

  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _idle.dispose();
    _child?.destroy();
    super.dispose();
  }

  void _togglePop() {
    if (_child != null) {
      _popKey.currentState?.close();
      return;
    }

    late final WindowController child;
    child = WindowController(
      size: kPopWindowSize,
      // Lock the size so the window keeps the size the pop animation was
      // designed for.
      constraints: BoxConstraints.tight(kPopWindowSize),
      title: 'POP!',
      delegate: _PopDelegate(
        // Clicking the title bar's close button plays the un-pop animation
        // before actually destroying the window.
        onCloseRequested: () => _popKey.currentState?.close(),
        onDestroyed: () {
          if (mounted && identical(_child, child)) {
            setState(() => _child = null);
          }
        },
      ),
    );
    setState(() => _child = child);
  }

  @override
  Widget build(BuildContext context) {
    final WindowController? child = _child;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E1A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Backdrop(),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Want desktop apps that…',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w300,
                    color: Color(0xCCFFFFFF),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 48),
                // Rendering the child window from here lets it inherit this
                // window's theme.
                ViewAnchor(
                  view: child == null
                      ? null
                      : Window(
                          controller: child,
                          child: PopWindowContent(
                            key: _popKey,
                            controller: child,
                          ),
                        ),
                  child: AnimatedBuilder(
                    animation: _idle,
                    builder: (context, _) => _PopButton(
                      glow: Curves.easeInOut.transform(_idle.value),
                      isOpen: child != null,
                      onPressed: _togglePop,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PopDelegate with WindowControllerDelegate {
  _PopDelegate({required this.onCloseRequested, required this.onDestroyed});

  final VoidCallback onCloseRequested;
  final VoidCallback onDestroyed;

  @override
  void onWindowCloseRequested(WindowController controller) {
    onCloseRequested();
  }

  @override
  void onWindowDestroyed() {
    onDestroyed();
    super.onWindowDestroyed();
  }
}

/// The big, glowing, squishy "POP!" button.
class _PopButton extends StatefulWidget {
  const _PopButton({
    required this.glow,
    required this.isOpen,
    required this.onPressed,
  });

  final double glow;
  final bool isOpen;
  final VoidCallback onPressed;

  @override
  State<_PopButton> createState() => _PopButtonState();
}

class _PopButtonState extends State<_PopButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final double scale = _pressed ? 0.9 : (_hovered ? 1.06 : 1.0);
    final double glow = 24 + widget.glow * 22 + (_hovered ? 16 : 0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: scale,
          duration: Duration(milliseconds: _pressed ? 80 : 450),
          curve: _pressed ? Curves.easeOut : Curves.elasticOut,
          child: Container(
            width: 260,
            height: 110,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(55),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF4D8D),
                  Color(0xFFFF8A3D),
                  Color(0xFFFFC93C),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4D8D).withValues(alpha: 0.55),
                  blurRadius: glow,
                  spreadRadius: glow / 6,
                ),
              ],
            ),
            child: Text(
              widget.isOpen ? 'pop back' : 'POP!',
              style: TextStyle(
                fontSize: widget.isOpen ? 34 : 52,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
                shadows: const [
                  Shadow(
                    color: Color(0x66000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle dotted grid + colored glows so the main window doesn't look empty.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BackdropPainter());
  }
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    void glow(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    glow(
      Offset(size.width * 0.15, size.height * 0.1),
      size.width * 0.5,
      const Color(0x556C5CE7),
    );
    glow(
      Offset(size.width * 0.9, size.height * 0.95),
      size.width * 0.5,
      const Color(0x44FF4D8D),
    );

    final dot = Paint()..color = const Color(0x18FFFFFF);
    const double spacing = 28;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, dot);
      }
    }

    // A soft vignette.
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: math.sqrt2 * 0.75,
          colors: const [Color(0x00000000), Color(0x99000000)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) => false;
}

const List<Color> _kPalette = [
  Color(0xFFFF4D8D),
  Color(0xFFFF8A3D),
  Color(0xFFFFC93C),
  Color(0xFF3DDC97),
  Color(0xFF42A5F5),
  Color(0xFF8E7CFF),
  Colors.white,
];

/// The size of the child window.
const Size kPopWindowSize = Size(640, 660);

/// The content of the regular child window.
///
/// When the window opens, a colored circle bursts out from the center to fill
/// it, followed by a shockwave, confetti, and a jelly-like card.
class PopWindowContent extends StatefulWidget {
  const PopWindowContent({super.key, required this.controller});

  final WindowController controller;

  @override
  State<PopWindowContent> createState() => PopWindowContentState();
}

class PopWindowContentState extends State<PopWindowContent>
    with TickerProviderStateMixin {
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  late final AnimationController _close = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  final List<_Particle> _particles = _Particle.burst(90, math.Random());

  @override
  void dispose() {
    _open.dispose();
    _close.dispose();
    super.dispose();
  }

  /// Plays the "un-pop" animation, then destroys the window.
  Future<void> close() async {
    if (_close.isAnimating || _close.isCompleted) {
      return;
    }
    _open.stop();
    await _close.forward();
    if (!widget.controller.isDestroyed) {
      widget.controller.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          close();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Material(
        color: const Color(0xFF05040C),
        child: AnimatedBuilder(
          animation: Listenable.merge([_open, _close]),
          builder: (context, _) {
            final double t = _open.value;
            final double c = _close.value;
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipPath(
                  clipper: _CircleRevealClipper(
                    // Elastic overshoot makes the color "splat" into the window.
                    const ElasticOutCurve(0.6)
                            .transform(const Interval(0.0, 0.4).transform(t)) *
                        (1 - Curves.easeIn.transform(c)),
                  ),
                  child: const _WindowBackground(),
                ),
                CustomPaint(
                  painter: _BurstPainter(
                    t: t,
                    fadeOut: c,
                    particles: _particles,
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _buildCard(t, c),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(double t, double c) {
    // The card pops slightly after the window starts springing open.
    final double p = const Interval(0.12, 0.7).transform(t);
    final double scale = const ElasticOutCurve(0.42).transform(p);
    final double decay = math.pow(1 - p, 2.2).toDouble();
    final double wobble = math.sin(p * math.pi * 7) * decay * 0.22;
    final double rotation = math.sin(p * math.pi * 4) * decay * 0.12;

    // Closing: a quick anticipation, then shrink to nothing.
    final double closeScale = 1 - Curves.easeInBack.transform(c);

    final double sx = (scale * (1 + wobble) * closeScale).clamp(0.0, 3.0);
    final double sy = (scale * (1 - wobble) * closeScale).clamp(0.0, 3.0);

    return Opacity(
      opacity: (math.min(1.0, p * 12) * (1 - c)).clamp(0.0, 1.0),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..rotateZ(rotation)
          ..scaleByDouble(sx, sy, 1, 1),
        child: _PopCard(t: t, onClose: close),
      ),
    );
  }
}

/// Soft colored glows behind everything in the child window.
class _WindowBackground extends StatelessWidget {
  const _WindowBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 0.9,
          colors: [Color(0xFF3A1D6E), Color(0xFF0E0B22)],
        ),
      ),
    );
  }
}

class _PopCard extends StatelessWidget {
  const _PopCard({required this.t, required this.onClose});

  final double t;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    // Staggered entrance for the card's children.
    final double logo = const ElasticOutCurve(0.5)
        .transform(const Interval(0.12, 0.6).transform(t));
    final double title = Curves.easeOutBack.transform(
      const Interval(0.22, 0.5).transform(t),
    );
    final double body = Curves.easeOutCubic.transform(
      const Interval(0.32, 0.6).transform(t),
    );
    final double button = Curves.easeOutBack.transform(
      const Interval(0.4, 0.7).transform(t),
    );

    return Container(
      width: 400,
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1E5C), Color(0xFF14183A)],
        ),
        border: Border.all(color: const Color(0x33FFFFFF), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x88FF4D8D), blurRadius: 60, spreadRadius: -6),
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: (1 - logo) * -math.pi,
            child: Transform.scale(
              scale: logo,
              child: Container(
                width: 104,
                height: 104,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x6642A5F5),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const FlutterLogo(size: 60),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Transform.translate(
            offset: Offset(0, (1 - title) * 30),
            child: Opacity(
              opacity: title.clamp(0.0, 1.0),
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [
                    Color(0xFFFF4D8D),
                    Color(0xFFFF8A3D),
                    Color(0xFFFFC93C),
                  ],
                ).createShader(rect),
                child: const Text(
                  'POP!',
                  style: TextStyle(
                    fontSize: 72,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Opacity(
            opacity: body,
            child: Transform.translate(
              offset: Offset(0, (1 - body) * 16),
              child: const Text(
                "Hi! I'm a brand new window,\ncreated by Flutter's windowing API.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.4,
                  color: Color(0xCCFFFFFF),
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          Transform.scale(
            scale: button.clamp(0.0, 2.0),
            child: FilledButton(
              onPressed: onClose,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2A1E5C),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 18,
                ),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Awesome!'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.spin,
    required this.isCircle,
    required this.delay,
  });

  final double angle;
  final double speed;
  final Color color;
  final double size;
  final double spin;
  final bool isCircle;
  final double delay;

  static List<_Particle> burst(int count, math.Random random) {
    return List<_Particle>.generate(count, (i) {
      return _Particle(
        angle: (i / count) * math.pi * 2 + random.nextDouble() * 0.4,
        speed: 260 + random.nextDouble() * 360,
        color: _kPalette[random.nextInt(_kPalette.length)],
        size: 5 + random.nextDouble() * 9,
        spin: (random.nextDouble() - 0.5) * 24,
        isCircle: random.nextBool(),
        delay: random.nextDouble() * 0.06,
      );
    });
  }
}

/// Paints the flash, shockwave rings, comic "pop" lines and confetti.
class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.t,
    required this.fadeOut,
    required this.particles,
  });

  final double t;
  final double fadeOut;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double maxRadius = size.shortestSide / 2;
    final double globalAlpha = 1 - fadeOut;

    // 1. Bright flash.
    final double flash = const Interval(0.0, 0.12).transform(t);
    if (flash < 1) {
      final double r = 40 + flash * 160;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: (1 - flash) * globalAlpha),
              const Color(0xFFFFC93C)
                  .withValues(alpha: (1 - flash) * 0.6 * globalAlpha),
              const Color(0x00FFC93C),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }

    // 2. Shockwave rings.
    void ring(double start, double end, Color color, double width) {
      final double p = Interval(start, end).transform(t);
      if (p <= 0 || p >= 1) {
        return;
      }
      final double eased = Curves.easeOutCubic.transform(p);
      canvas.drawCircle(
        center,
        30 + eased * (maxRadius - 40),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * (1 - p) + 0.5
          ..color = color.withValues(alpha: (1 - p) * globalAlpha),
      );
    }

    ring(0.0, 0.42, const Color(0xFFFF4D8D), 18);
    ring(0.05, 0.5, const Color(0xFFFFC93C), 10);
    ring(0.1, 0.6, const Color(0xFF8E7CFF), 6);

    // 3. Comic-book "pop" lines radiating outward.
    final double lines = Curves.easeOutCubic.transform(
      const Interval(0.02, 0.32).transform(t),
    );
    if (lines > 0 && lines < 1) {
      const int count = 16;
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 7 * (1 - lines) + 1
        ..color = Colors.white.withValues(alpha: (1 - lines) * globalAlpha);
      for (int i = 0; i < count; i++) {
        final double a = i / count * math.pi * 2 + math.pi / count;
        final double inner = 120 + lines * 200;
        final double outer = inner + 70 * (1 - lines) + 10;
        final dir = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(center + dir * inner, center + dir * outer, paint);
      }
    }

    // 4. Confetti with drag & gravity.
    const double gravity = 900;
    const double drag = 2.4;
    const double totalSeconds = 1.6;
    for (final _Particle particle in particles) {
      final double local = ((t - particle.delay) / (1 - particle.delay)).clamp(
        0.0,
        1.0,
      );
      if (local <= 0) {
        continue;
      }
      final double s = local * totalSeconds;
      // Velocity decays exponentially; integrate for position.
      final double travel = particle.speed * (1 - math.exp(-drag * s)) / drag;
      final double fall = 0.5 * gravity * s * s * 0.35;
      final Offset pos =
          center +
          Offset(math.cos(particle.angle), math.sin(particle.angle)) *
              (40 + travel) +
          Offset(0, fall);

      final double alpha =
          (local < 0.65 ? 1.0 : 1 - (local - 0.65) / 0.35) * globalAlpha;
      if (alpha <= 0) {
        continue;
      }
      final paint = Paint()
        ..color = particle.color.withValues(alpha: alpha.clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(particle.spin * s);
      if (particle.isCircle) {
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      } else {
        // Flip the rectangle's height over time to fake 3D tumbling.
        final double flip = math.cos(particle.spin * s * 0.7).abs();
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size * 0.55 * (0.2 + 0.8 * flip),
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.fadeOut != fadeOut;
}

/// Clips its child to a circle growing from the center. At `progress == 1`
/// the circle covers the whole area; values above 1 (elastic overshoot) are
/// fine and simply cover it too.
class _CircleRevealClipper extends CustomClipper<Path> {
  _CircleRevealClipper(this.progress);

  final double progress;

  @override
  Path getClip(Size size) {
    final double maxRadius = size.center(Offset.zero).distance;
    return Path()..addOval(
      Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: maxRadius * progress.clamp(0.0, 2.0),
      ),
    );
  }

  @override
  bool shouldReclip(_CircleRevealClipper oldClipper) =>
      oldClipper.progress != progress;
}
