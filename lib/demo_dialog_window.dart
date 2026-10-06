// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

// A plain Material counter app. Pressing the increment button opens a
// native dialog window asking you to confirm the increment.
//
// Run with: flutter run -d macos -t lib/demo_dialog_window.dart

import 'dart:ui' show AppExitType;

import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/_window.dart';
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

  DialogWindowController? _dialog;

  void _showConfirmDialog() {
    if (_dialog != null) {
      return;
    }

    final dialog = DialogWindowController(
      // A parent makes the dialog modal to the main window.
      parent: widget.windowController,
      size: const Size(360, 160),
      title: 'Confirm',
      delegate: DialogDelegate(
        onDestroyed: () {
          if (mounted) {
            setState(() => _dialog = null);
          }
        },
      ),
    );

    setState(() => _dialog = dialog);
  }

  void _onConfirmed() {
    setState(() => _counter++);
    _closeDialog();
  }

  void _onCancelled() {
    _closeDialog();
  }

  Future<void> _closeDialog() async {
    final DialogWindowController? dialog = _dialog;
    if (dialog == null) {
      return;
    }

    // Remove the dialog's content from the widget tree first, then destroy
    // the native window once that frame is done. On macOS, destroying a
    // dialog that is still in the tree can crash the app.
    setState(() => _dialog = null);
    await WidgetsBinding.instance.endOfFrame;
    dialog.destroy();
  }

  @override
  Widget build(BuildContext context) {
    final DialogWindowController? dialog = _dialog;

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
      // The dialog window's content is built here so that it inherits the
      // app's theme.
      floatingActionButton: ViewAnchor(
        view: dialog == null
            ? null
            : DialogWindow(
                controller: dialog,
                child: ConfirmDialog(
                  onConfirm: _onConfirmed,
                  onCancel: _onCancelled,
                ),
              ),
        child: FloatingActionButton(
          onPressed: _showConfirmDialog,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class DialogDelegate with DialogWindowControllerDelegate {
  DialogDelegate({required this.onDestroyed});

  final VoidCallback onDestroyed;

  @override
  void onWindowDestroyed() {
    onDestroyed();
    super.onWindowDestroyed();
  }
}

/// The content of the confirmation dialog window.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Increment the counter?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onCancel, child: const Text('Cancel')),
                const SizedBox(width: 8),
                FilledButton(
                  autofocus: true,
                  onPressed: onConfirm,
                  child: const Text('Increment'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
