import 'dart:typed_data';

/// Tipos de mensagem que o chat sabe renderizar.
enum ChatMessageType {
  /// Foto enviada pelo usuário (bolha à direita).
  userPhoto,

  /// Resposta do coach em texto (bolha à esquerda).
  coachText,

  /// Indicador de "digitando..." do coach.
  typing,
}

/// Uma mensagem do chat.
///
/// Cada tipo usa só o campo que lhe interessa: [photoBytes] para
/// [ChatMessageType.userPhoto], [text] para [ChatMessageType.coachText] e
/// nenhum dos dois para [ChatMessageType.typing].
class ChatMessage {
  const ChatMessage._({required this.type, this.photoBytes, this.text});

  /// Foto escolhida pelo usuário, já em memória (funciona também na web).
  const ChatMessage.userPhoto(Uint8List bytes)
    : this._(type: ChatMessageType.userPhoto, photoBytes: bytes);

  /// Texto do coach.
  const ChatMessage.coachText(String message)
    : this._(type: ChatMessageType.coachText, text: message);

  /// Bolha de "digitando" enquanto o coach "pensa".
  const ChatMessage.typing() : this._(type: ChatMessageType.typing);

  final ChatMessageType type;
  final Uint8List? photoBytes;
  final String? text;
}
