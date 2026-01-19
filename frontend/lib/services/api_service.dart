import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/room.dart';
import '../config/app_config.dart';

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  // 登入
  Future<User> login(String nickname) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'nickname': nickname}),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('登入失敗');
    }
  }

  // 創建直播間
  Future<Map<String, dynamic>> createRoom(String token, String title) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rooms'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: json.encode({'title': title}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('創建直播間失敗');
    }
  }

  // 獲取直播間列表
  Future<List<Room>> getRooms() async {
    final response = await http.get(Uri.parse('$baseUrl/rooms'));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Room.fromJson(json)).toList();
    } else {
      throw Exception('獲取直播間列表失敗');
    }
  }

  // 獲取單個房間
  Future<Room> getRoom(String roomId) async {
    final response = await http.get(Uri.parse('$baseUrl/rooms/$roomId'));

    if (response.statusCode == 200) {
      return Room.fromJson(json.decode(response.body));
    } else {
      throw Exception('獲取房間失敗');
    }
  }

  // 獲取播放地址
  Future<PlayUrls> getPlayUrls(String roomId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/rooms/$roomId/play_url'),
    );

    if (response.statusCode == 200) {
      return PlayUrls.fromJson(json.decode(response.body));
    } else {
      throw Exception('獲取播放地址失敗');
    }
  }

  // 更新直播間狀態（開始/停止直播）
  Future<void> updateRoomStatus(String token, String roomId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/rooms/$roomId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: json.encode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('更新直播間狀態失敗');
    }
  }

  // 刪除直播間
  Future<void> deleteRoom(String token, String roomId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/rooms/$roomId'),
      headers: {
        'Authorization': token,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('刪除直播間失敗');
    }
  }
}
