import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_message.dart';

/// Paleta do app.
const Color kBackground = Color(0xFF0D0E12);
const Color kSurface = Color(0xFF16181F);
const Color kBorder = Color(0xFF2A2D37);
const Color kText = Color(0xFFF4F4F1);
const Color kTextMuted = Color(0xFF8A8E9A);
const Color kAccent = Color(0xFFFF5A1F);
const Color kOnAccent = Color(0xFF150A04);
const Color kOnAccentMuted = Color(0xFF5A2C12);

const String _kWelcomeText =
    'E aí! 👋 Chegou num aparelho que não conhece?'
    '\n\nManda uma **foto** dele que eu te falo o **nome**, '
    'os **músculos** e te mostro **vídeo + fotos** da execução.';

const String _kPhotoReceivedText =
    'Foto recebida! 📸 A identificação por IA entra no próximo passo.';

/// Quanto tempo o coach fica "digitando" antes de responder.
const Duration _kFakeReplyDelay = Duration(seconds: 2);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [
    const ChatMessage.coachText(_kWelcomeText),
  ];
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  Timer? _replyTimer;

  /// O coach está "digitando" — o botão de foto fica travado nesse meio-tempo.
  bool get _isTyping => _messages.any((m) => m.type == ChatMessageType.typing);

  @override
  void dispose() {
    _replyTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _onTakePhoto() async {
    final XFile? photo = await _picker.pickImage(
      // Na web o picker não abre câmera, então cai pra galeria.
      source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 80,
    );
    // Usuário cancelou.
    if (photo == null) return;

    final bytes = await photo.readAsBytes();
    if (!mounted) return;

    setState(() {
      _messages.add(ChatMessage.userPhoto(bytes));
      _messages.add(const ChatMessage.typing());
    });
    _scrollToBottom();

    _replyTimer?.cancel();
    _replyTimer = Timer(_kFakeReplyDelay, () {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.type == ChatMessageType.typing);
        _messages.add(const ChatMessage.coachText(_kPhotoReceivedText));
      });
      _scrollToBottom();
    });
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
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                itemCount: _messages.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  switch (message.type) {
                    case ChatMessageType.coachText:
                      return _CoachRow(child: _CoachBubble(message.text!));
                    case ChatMessageType.typing:
                      return const _CoachRow(child: _TypingBubble());
                    case ChatMessageType.userPhoto:
                      return _UserPhotoBubble(message.photoBytes!);
                  }
                },
              ),
            ),
            _Composer(onTakePhoto: _isTyping ? null : _onTakePhoto),
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
                TextSpan(
                  text: '.',
                  style: TextStyle(color: kAccent),
                ),
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

/// Avatar do coach + a bolha dele, alinhados à esquerda.
class _CoachRow extends StatelessWidget {
  const _CoachRow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
        Flexible(child: child),
      ],
    );
  }
}

/// Caixa de fundo cinza com o "bico" no canto superior esquerdo.
class _CoachShell extends StatelessWidget {
  const _CoachShell({required this.padding, required this.child});

  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
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
      child: child,
    );
  }
}

class _CoachBubble extends StatelessWidget {
  const _CoachBubble(this.text);

  final String text;

  /// Trechos entre `**` viram negrito.
  List<TextSpan> _spans() {
    const bold = TextStyle(fontWeight: FontWeight.bold);
    final parts = text.split('**');
    return [
      for (var i = 0; i < parts.length; i++)
        TextSpan(text: parts[i], style: i.isOdd ? bold : null),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return _CoachShell(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text.rich(
        TextSpan(children: _spans()),
        style: const TextStyle(color: kText, fontSize: 14, height: 1.45),
      ),
    );
  }
}

/// Três pontinhos pulsando em loop, sem pacote externo.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CoachShell(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            _TypingDot(controller: _controller, index: i),
          ],
        ],
      ),
    );
  }
}

class _TypingDot extends StatelessWidget {
  const _TypingDot({required this.controller, required this.index});

  final AnimationController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    // Cada ponto começa 0.15 do ciclo depois do anterior.
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(index * 0.15, index * 0.15 + 0.5),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Sobe até a metade da janela e volta.
        final progress = animation.value <= 0.5
            ? animation.value * 2
            : (1 - animation.value) * 2;
        final t = Curves.easeInOut.transform(progress);
        return Opacity(
          opacity: 0.35 + 0.65 * t,
          child: Transform.translate(offset: Offset(0, -3 * t), child: child),
        );
      },
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: kTextMuted,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Foto enviada pelo usuário: bolha laranja, alinhada à direita.
class _UserPhotoBubble extends StatelessWidget {
  const _UserPhotoBubble(this.bytes);

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: const BoxDecoration(
            color: kAccent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(5),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(bytes, width: 200, fit: BoxFit.cover),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 5, 4, 1),
                child: Text(
                  'enviei essa foto ↑',
                  style: TextStyle(
                    color: kOnAccentMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.onTakePhoto});

  /// `null` trava o botão (enquanto o coach está "digitando").
  final VoidCallback? onTakePhoto;

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
                disabledBackgroundColor: kAccent.withValues(alpha: 0.35),
                disabledForegroundColor: kOnAccent.withValues(alpha: 0.5),
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
