import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/presentation/screens/chat_screen.dart';

void main() {
  runApp(const ProviderScope(child: SynapApp()));
}

class SynapApp extends StatelessWidget {
  const SynapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synap',
      debugShowCheckedModeBanner: false,
      home: const ChatScreen(),
    );
  }
}
