import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'recorder/recorder_controller.dart';
import 'ui/home_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initForegroundTask();
  runApp(const ProviderScope(child: ThrottlePathApp()));
}

class ThrottlePathApp extends StatelessWidget {
  const ThrottlePathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Throttle Path',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const HomeScreen(),
    );
  }
}
