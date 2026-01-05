class User {
  final String id;
  final String nickname;
  final String token;

  User({
    required this.id,
    required this.nickname,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'],
      nickname: json['nickname'],
      token: json['token'],
    );
  }
}

