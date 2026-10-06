// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/src/widgets/_window.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = WindowController(
    size: const Size(575, 450),
    title: 'Flutter Windowing',
  );

  runWidget(
    Window(
      controller: controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Text('TODO')),
      ),
    ),
  );
}
