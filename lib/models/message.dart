class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final int timestamp;
  final bool isWolfOnly;
  final bool isMassoniOnly;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isWolfOnly = false,
    this.isMassoniOnly = false,
  });

  factory Message.fromMap(String id, Map<dynamic, dynamic> map) {
    return Message(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      isWolfOnly: map['isWolfOnly'] ?? false,
      isMassoniOnly: map['isMassoniOnly'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp,
      'isWolfOnly': isWolfOnly,
      'isMassoniOnly': isMassoniOnly,
    };
  }
}
