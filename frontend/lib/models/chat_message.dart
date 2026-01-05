class ChatMessage {
  final String roomId;
  final String userId;
  final String nickname;
  final String message;
  final DateTime time;

  ChatMessage({
    required this.roomId,
    required this.userId,
    required this.nickname,
    required this.message,
    required this.time,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      roomId: json['room_id'],
      userId: json['user_id'],
      nickname: json['nickname'],
      message: json['message'],
      time: DateTime.parse(json['time']),
    );
  }

  bool get isSystem => userId == 'system';
}

