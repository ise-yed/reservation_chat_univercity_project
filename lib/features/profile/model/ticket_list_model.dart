class TicketListModel {
  String? id;
  String? user;
  String? subject;
  String? description;
  String? status;
  DateTime? modified;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;

  TicketListModel({
    this.id,
    this.user,
    this.subject,
    this.description,
    this.status,
    this.modified,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory TicketListModel.fromJson(Map<String, dynamic> json) {
    return TicketListModel(
      id: json['_id'],
      user: json['user'],
      subject: json['subject'],
      description: json['description'],
      status: json['status'],
      modified: json['modified'] != null ? DateTime.parse(json['modified']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      v: json['__v'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user,
      'subject': subject,
      'description': description,
      'status': status,
      'modified': modified?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      '__v': v,
    };
  }
}
List<TicketListModel> ticketListModelFromJson(List<dynamic> data) {
  return data.map((e) => TicketListModel.fromJson(e)).toList();
}
