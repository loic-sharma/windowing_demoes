// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

// A plain Material counter app. Hovering over the increment button shows a
// native tooltip window.
//
// Run with: flutter run -d macos -t lib/demo_tooltip_window.dart

import 'dart:ui' show AppExitType;

import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter/src/widgets/_window_positioner.dart';
import 'package:material_ui/material_ui.dart';

class MainWindowDelegate with WindowControllerDelegate {
  @override
  void onWindowDestroyed() {
    super.onWindowDestroyed();
    ServicesBinding.instance.exitApplication(AppExitType.required);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = WindowController(
    size: const Size(575, 450),
    title: 'Counter',
    delegate: MainWindowDelegate(),
  );

  runWidget(
    Window(
      controller: controller,
      child: MaterialApp(
        title: 'Counter',
        debugShowCheckedModeBanner: false,
        home: CounterPage(windowController: controller),
      ),
    ),
  );
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key, required this.windowController});

  final WindowController windowController;

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  final GlobalKey _buttonKey = GlobalKey();

  int _counter = 0;

  TooltipWindowController? _tooltip;

  void _showTooltip() {
    if (_tooltip != null) {
      return;
    }

    // The tooltip is positioned relative to this rectangle, in the main
    // window's coordinates.
    final box = _buttonKey.currentContext!.findRenderObject()! as RenderBox;
    final Rect buttonRect = box.localToGlobal(Offset.zero) & box.size;

    final tooltip = TooltipWindowController(
      parent: widget.windowController,
      anchorRect: buttonRect,
      // Place the tooltip's bottom-left corner just above the button's
      // top-left corner.
      positioner: const WindowPositioner(
        parentAnchor: WindowPositionerAnchor.topLeft,
        childAnchor: WindowPositionerAnchor.bottomLeft,
        offset: Offset(0, -8),
      ),
      delegate: TooltipDelegate(
        onDestroyed: () {
          if (mounted) {
            setState(() => _tooltip = null);
          }
        },
      ),
    );

    setState(() => _tooltip = tooltip);
  }

  void _hideTooltip() {
    _tooltip?.destroy();
  }

  void _increment() {
    setState(() => _counter++);
  }

  @override
  Widget build(BuildContext context) {
    final TooltipWindowController? tooltip = _tooltip;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Counter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      // The tooltip window's content is built here so that it inherits the
      // app's theme.
      floatingActionButton: ViewAnchor(
        view: tooltip == null
            ? null
            : TooltipWindow(
                controller: tooltip,
                child: const IncrementTooltip(),
              ),
        child: MouseRegion(
          onEnter: (_) => _showTooltip(),
          onExit: (_) => _hideTooltip(),
          child: FloatingActionButton(
            key: _buttonKey,
            onPressed: _increment,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

class TooltipDelegate with TooltipWindowControllerDelegate {
  TooltipDelegate({required this.onDestroyed});

  final VoidCallback onDestroyed;

  @override
  void onWindowDestroyed() {
    onDestroyed();
    super.onWindowDestroyed();
  }
}

/// The content of the tooltip window.
///
/// Tooltip windows are borderless and transparent, so the tooltip draws its
/// own card background. The window sizes itself to fit this content.
class IncrementTooltip extends StatelessWidget {
  const IncrementTooltip({super.key});

  @override
  Widget build(BuildContext context) {
    return Overlay.wrap(
      alwaysSizeToContent: true,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Increment tooltip',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text('Increment by 1'),
            ],
          ),
        ),
      ),
    );
  }
}
