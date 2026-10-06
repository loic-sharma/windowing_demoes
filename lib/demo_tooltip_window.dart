// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

// A plain Material counter app. Pressing the increment button opens a native
// popup window where you can choose how much to increment the counter by.
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
        // theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
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

  void _toggleTooltip() {
    if (_tooltip != null) {
      _tooltip!.destroy();
      return;
    }

    // The popup is positioned relative to this rectangle, in the main
    // window's coordinates.
    final box = _buttonKey.currentContext!.findRenderObject()! as RenderBox;
    final Rect buttonRect = box.localToGlobal(Offset.zero) & box.size;

    final popup = TooltipWindowController(
      parent: widget.windowController,
      anchorRect: buttonRect,
      // Place the popup's bottom-right corner just above the button's
      // top-right corner.
      positioner: const WindowPositioner(
        parentAnchor: WindowPositionerAnchor.topLeft,
        childAnchor: WindowPositionerAnchor.bottomLeft,
        offset: Offset(0, -8),
      ),
      delegate: TooltipDelegate(
        // Popups also close when another window gets focus.
        onDestroyed: () {
          if (mounted) {
            setState(() => _tooltip = null);
          }
        },
      ),
    );

    setState(() => _tooltip = popup);
  }

  void _increment(int amount) {
    setState(() => _counter += amount);
  }

  @override
  Widget build(BuildContext context) {
    final TooltipWindowController? popup = _tooltip;

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
      // The popup window's content is built here so that it inherits the
      // app's theme.
      floatingActionButton: ViewAnchor(
        view: popup == null
            ? null
            : TooltipWindow(
                controller: popup,
                child: IncrementTooltip(onIncrement: _increment),
              ),
        child: MouseRegion(
          onEnter: (_) {
            if (popup == null) {
              _toggleTooltip();
            }
          },
          onExit: (_) {
            if (popup != null) {
              _toggleTooltip();
            }
          },
          child: FloatingActionButton(
            key: _buttonKey,
            onPressed: () => _increment(1),
            // tooltip: 'Increment',
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

/// The content of the popup window.
///
/// Popup windows are borderless and transparent, so the popup draws its own
/// card background. The window sizes itself to fit this content.
class IncrementTooltip extends StatelessWidget {
  const IncrementTooltip({super.key, required this.onIncrement});

  final ValueChanged<int> onIncrement;

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
              Text('Increment by 1'),
            ],
          ),
        ),
      ),
    );
  }
}
