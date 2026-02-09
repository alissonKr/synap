import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Synap'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, 'chat'),
          child: const Text('Start Chat'),
        ),
      ),
    );
  }
}
