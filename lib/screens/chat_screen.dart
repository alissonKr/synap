import 'package:flutter/material.dart';

/// Paleta do app.
const Color kBackground = Color(0xFF0D0E12);
const Color kSurface = Color(0xFF16181F);
const Color kBorder = Color(0xFF2A2D37);
const Color kText = Color(0xFFF4F4F1);
const Color kTextMuted = Color(0xFF8A8E9A);
const Color kAccent = Color(0xFFFF5A1F);
const Color kOnAccent = Color(0xFF150A04);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  void _onTakePhoto() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('📸 A câmera entra no próximo passo!'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                children: const [_WelcomeBubble()],
              ),
            ),
            _Composer(onTakePhoto: _onTakePhoto),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text.rich(
            TextSpan(
              text: 'SYNAP',
              children: [
                TextSpan(text: '.', style: TextStyle(color: kAccent)),
              ],
            ),
            style: TextStyle(
              color: kText,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'foto do aparelho → como treinar',
            style: TextStyle(color: kTextMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBubble extends StatelessWidget {
  const _WelcomeBubble();

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(color: kText, fontSize: 14, height: 1.45);
    const bold = TextStyle(fontWeight: FontWeight.bold);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kAccent.withValues(alpha: 0.15),
            border: Border.all(color: kAccent.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('🏋️', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: kSurface,
              border: Border.all(color: kBorder),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: const Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'E aí! 👋 Chegou num aparelho que não conhece?'),
                  TextSpan(text: '\n\nManda uma '),
                  TextSpan(text: 'foto', style: bold),
                  TextSpan(text: ' dele que eu te falo o '),
                  TextSpan(text: 'nome', style: bold),
                  TextSpan(text: ', os '),
                  TextSpan(text: 'músculos', style: bold),
                  TextSpan(text: ' e te mostro '),
                  TextSpan(text: 'vídeo + fotos', style: bold),
                  TextSpan(text: ' da execução.'),
                ],
              ),
              style: base,
            ),
          ),
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.onTakePhoto});

  final VoidCallback onTakePhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTakePhoto,
              icon: const Icon(Icons.photo_camera_rounded, size: 20),
              label: const Text('TIRAR FOTO DO APARELHO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                foregroundColor: kOnAccent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Aponte pra máquina que não conhece',
            style: TextStyle(color: kTextMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
