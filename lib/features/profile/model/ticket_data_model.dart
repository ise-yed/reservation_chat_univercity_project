class SingleTicketModel {
  final String? id;
  final String? user;
  final String? subject;
  final String? description;
  final String? status;
  final String? modified;
  final String? createdAt;
  final String? updatedAt;
  final int? v;
  final List<TicketMessageData>? messages;

  SingleTicketModel({
    this.id,
    this.user,
    this.subject,
    this.description,
    this.status,
    this.modified,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.messages,
  });

  factory SingleTicketModel.fromJson(Map<String, dynamic> json) {
    return SingleTicketModel(
      id: json["_id"],
      user: json["user"],
      subject: json["subject"],
      description: json["description"],
      status: json["status"],
      modified: json["modified"],
      createdAt: json["createdAt"],
      updatedAt: json["updatedAt"],
      v: json["__v"],
      messages: (json["messages"] as List<dynamic>?)
          ?.map((e) => TicketMessageData.fromJson(e))
          .toList(),
    );
  }
}



class TicketMessageData {
  final String? id;
  final String? type;
  final String? user;
  final String? ticket;
  final String? message;
  final String? document;
  final String? createdAt;
  final String? updatedAt;
  final int? v;

  TicketMessageData({
    this.id,
    this.type,
    this.user,
    this.ticket,
    this.message,
    this.document,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory TicketMessageData.fromJson(Map<String, dynamic> json) {
    return TicketMessageData(
      id: json["_id"],
      type: json["type"],
      user: json["user"],
      ticket: json["ticket"],
      message: json["message"],
      document: json["document"],
      createdAt: json["createdAt"],
      updatedAt: json["updatedAt"],
      v: json["__v"],
    );
  }
}
