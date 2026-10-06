// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

// A plain Material counter app. The main window shows the counter, and a
// satellite window to its right holds the increment button.
//
// Run with: flutter run -d <device> -t lib/demo_satellite_window.dart
//
// Note: satellite windows are not yet implemented on macOS.

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
        theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
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
  int _counter = 0;

  SatelliteWindowController? _satellite;

  @override
  void initState() {
    super.initState();
    _satellite = _createSatellite();
  }

  @override
  void dispose() {
    _satellite?.destroy();
    super.dispose();
  }

  SatelliteWindowController _createSatellite() {
    return SatelliteWindowController(
      parent: widget.windowController,
      size: const Size(200, 200),
      title: 'Controls',
      // With no anchor rectangle, the satellite is positioned relative to the
      // main window. Place its top-left corner just right of the main
      // window's top-right corner. The satellite then follows the main
      // window when it moves.
      initialPositioner: const WindowPositioner(
        parentAnchor: WindowPositionerAnchor.topRight,
        childAnchor: WindowPositionerAnchor.topLeft,
        offset: Offset(8, 0),
      ),
      delegate: SatelliteDelegate(
        onDestroyed: () {
          if (mounted) {
            setState(() => _satellite = null);
          }
        },
      ),
    );
  }

  void _showSatellite() {
    if (_satellite == null) {
      setState(() => _satellite = _createSatellite());
    }
  }

  void _increment() {
    setState(() => _counter++);
  }

  @override
  Widget build(BuildContext context) {
    final SatelliteWindowController? satellite = _satellite;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Counter'),
      ),
      // The satellite window's content is built here so that it inherits the
      // app's theme and shares the counter's state.
      body: ViewAnchor(
        view: satellite == null
            ? null
            : SatelliteWindow(
                controller: satellite,
                child: IncrementControls(onIncrement: _increment),
              ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You have pushed the button this many times:'),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              // Lets you bring the controls back if you close the satellite.
              if (satellite == null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _showSatellite,
                  child: const Text('Show controls'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SatelliteDelegate with SatelliteWindowControllerDelegate {
  SatelliteDelegate({required this.onDestroyed});

  final VoidCallback onDestroyed;

  @override
  void onWindowDestroyed() {
    onDestroyed();
    super.onWindowDestroyed();
  }
}

/// The content of the satellite window.
class IncrementControls extends StatelessWidget {
  const IncrementControls({super.key, required this.onIncrement});

  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    // The satellite is its own window, so it needs its own overlay for things
    // like the button's tooltip.
    return Overlay.wrap(
      child: Scaffold(
        body: Center(
          child: FloatingActionButton(
            onPressed: onIncrement,
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
