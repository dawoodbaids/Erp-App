import 'json_helpers.dart';

class User {
  final String id;
  final String username;
  final String displayName;

  const User({
    required this.id,
    required this.username,
    required this.displayName,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: toStr(json['id']),
    username: toStr(json['username']),
    displayName: toStr(json['fullName'] ?? json['displayName']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'fullName': displayName,
  };
}
