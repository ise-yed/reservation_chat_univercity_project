class NotificationModel {
  final List<NotificationDoc> docs;
  final int totalDocs;
  final int limit;
  final int totalPages;
  final int page;
  final int pagingCounter;
  final bool hasPrevPage;
  final bool hasNextPage;
  final int? prevPage;
  final int? nextPage;
  final int unseen;

  NotificationModel({
    required this.docs,
    required this.totalDocs,
    required this.limit,
    required this.totalPages,
    required this.page,
    required this.pagingCounter,
    required this.hasPrevPage,
    required this.hasNextPage,
    this.prevPage,
    this.nextPage,
    required this.unseen,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      docs: (json['docs'] as List<dynamic>)
          .map((e) => NotificationDoc.fromJson(e))
          .toList(),
      totalDocs: json['totalDocs'],
      limit: json['limit'],
      totalPages: json['totalPages'],
      page: json['page'],
      pagingCounter: json['pagingCounter'],
      hasPrevPage: json['hasPrevPage'],
      hasNextPage: json['hasNextPage'],
      prevPage: json['prevPage'],
      nextPage: json['nextPage'],
      unseen: json['unseen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'docs': docs.map((e) => e.toJson()).toList(),
      'totalDocs': totalDocs,
      'limit': limit,
      'totalPages': totalPages,
      'page': page,
      'pagingCounter': pagingCounter,
      'hasPrevPage': hasPrevPage,
      'hasNextPage': hasNextPage,
      'prevPage': prevPage,
      'nextPage': nextPage,
      'unseen': unseen,
    };
  }
}

// ✅ Single notification item
class NotificationDoc {
  final String id;
  final String title;
  final String message;
  final String type;
  final String content;
  final String receiver;
  final bool seen;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationDoc({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.content,
    required this.receiver,
    required this.seen,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationDoc.fromJson(Map<String, dynamic> json) {
    return NotificationDoc(
      id: json['_id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      content: json['content'],
      receiver: json['receiver'],
      seen: json['seen'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'message': message,
      'type': type,
      'content': content,
      'receiver': receiver,
      'seen': seen,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
