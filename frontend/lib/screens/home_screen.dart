import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/room.dart';
import '../services/api_service.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  List<Room> _rooms = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadRooms();
    // 每 3 秒刷新一次直播間列表
    _timer = Timer.periodic(Duration(seconds: 3), (_) => _loadRooms());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await _apiService.getRooms();
      setState(() {
        _rooms = rooms;
        _loading = false;
      });
    } catch (e) {
      print('加載直播間失敗: $e');
      setState(() => _loading = false);
    }
  }

  void _goToMyRoom() async {
    try {
      print('🏠 [我的直播間] 獲取我的直播間...');

      // 調用 API 獲取我的直播間
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/rooms/my'),
        headers: {'Authorization': widget.user.token},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final room = Room(
          id: data['id'],
          title: data['title'],
          hostId: data['host_id'],
          streamKey: data['stream_key'],
          status: data['status'],
          viewerCount: data['viewer_count'] ?? 0,
        );

        print('✅ [我的直播間] 找到直播間: ${room.title}');

        // 跳轉到播放器頁面（主播控制面板）
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(
              user: widget.user,
              room: room,
            ),
          ),
        );
      } else if (response.statusCode == 404) {
        // 沒有直播間，提示創建
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('你還沒有創建直播間，請點擊「開始直播」創建'),
            action: SnackBarAction(
              label: '創建',
              onPressed: _createRoom,
            ),
          ),
        );
      } else {
        throw Exception('Failed to get my room');
      }
    } catch (e) {
      print('❌ [我的直播間] 獲取失敗: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('獲取直播間失敗: $e')),
      );
    }
  }

  void _createRoom() async {
    try {
      final title = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: Text('創建直播間'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '直播間標題',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  print('👈 點擊取消');
                  Navigator.pop(context);
                },
                child: Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  print('👈 點擊創建: ${controller.text}');
                  Navigator.pop(context, controller.text);
                },
                child: Text('創建'),
              ),
            ],
          );
        },
      );

      print('📝 用戶輸入的標題: $title');

      if (title != null && title.isNotEmpty) {
        print('✅ 開始創建直播間: $title');
        final result = await _apiService.createRoom(widget.user.token, title);
        print('✅ API 回應: $result');

        // 創建房間物件
        final room = Room(
          id: result['room_id'],
          title: result['title'],
          hostId: widget.user.id,
          streamKey: result['stream_key'],
          status: 'idle',
          viewerCount: 0,
        );

        print('✅ 跳轉到播放器頁面');
        // 跳轉到 PlayerScreen（房主控制面板）
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(
              user: widget.user,
              room: room,
            ),
          ),
        );
      } else {
        print('❌ 標題為空或用戶取消');
      }
    } catch (e) {
      print('❌ 創建直播間錯誤: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('創建直播間失敗: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('直播間列表'),
        actions: [
          // 我的直播間按鈕
          IconButton(
            icon: Icon(Icons.person),
            tooltip: '我的直播間',
            onPressed: _goToMyRoom,
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(widget.user.nickname),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _rooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.live_tv_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('暫無直播間', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRooms,
                  child: ListView.builder(
                    itemCount: _rooms.length,
                    itemBuilder: (context, index) {
                      final room = _rooms[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: Icon(
                            room.isLive ? Icons.play_circle : Icons.stop_circle,
                            color: room.isLive ? Colors.red : Colors.grey,
                            size: 40,
                          ),
                          title: Text(room.title, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('觀看人數: ${room.viewerCount}'),
                          trailing: room.isLive
                              ? Chip(
                                  label: Text('直播中', style: TextStyle(color: Colors.white)),
                                  backgroundColor: Colors.red,
                                )
                              : null,
                          onTap: room.isLive
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlayerScreen(
                                        user: widget.user,
                                        room: room,
                                      ),
                                    ),
                                  )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createRoom,
        icon: Icon(Icons.videocam),
        label: Text('開始直播'),
      ),
    );
  }
}
