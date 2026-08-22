import 'package:flutter/material.dart';

import 'screens/chat_screen.dart';

void main() {
  runApp(const SynapApp());
}

class SynapApp extends StatelessWidget {
  const SynapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBackground,
        colorScheme: const ColorScheme.dark(
          primary: kAccent,
          surface: kSurface,
        ),
      ),
      home: const ChatScreen(),
    );
  }
}
