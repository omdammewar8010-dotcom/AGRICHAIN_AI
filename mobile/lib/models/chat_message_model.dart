class ChatMessageModel {
  final String text;
  final bool isUser;
  final List<String> keyTakeaways;
  final List<String> suggestedActions;
  final DateTime timestamp;

  const ChatMessageModel({
    required this.text,
    required this.isUser,
    this.keyTakeaways = const [],
    this.suggestedActions = const [],
    required this.timestamp,
  });
}
