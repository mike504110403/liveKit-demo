class Room {
  final String id;
  final String title;
  final String streamKey;
  final String status;
  final String hostId;
  final int viewerCount;

  Room({
    required this.id,
    required this.title,
    required this.streamKey,
    required this.status,
    required this.hostId,
    required this.viewerCount,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      title: json['title'],
      streamKey: json['stream_key'],
      status: json['status'],
      hostId: json['host_id'],
      viewerCount: json['viewer_count'] ?? 0,
    );
  }

  bool get isLive => status == 'live';
}

class PlayUrls {
  final String hls;
  final String flv;

  PlayUrls({required this.hls, required this.flv});

  factory PlayUrls.fromJson(Map<String, dynamic> json) {
    return PlayUrls(
      hls: json['hls'],
      flv: json['flv'],
    );
  }
}

