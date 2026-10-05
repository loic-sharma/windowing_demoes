// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:material_ui/material_ui.dart';

import 'pop_window.dart';

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
