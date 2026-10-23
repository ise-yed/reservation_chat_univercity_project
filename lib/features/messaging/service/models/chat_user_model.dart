class ChatUserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String phoneNumber;
  final bool isVerified;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChatUserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.phoneNumber,
    required this.isVerified,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  bool get isProvider => role == 'provider';
  bool get isCustomer => role == 'customer';

  String get displayName {
    if (fullName.trim().isNotEmpty) return fullName.trim();
    final combined = '$firstName $lastName'.trim();
    if (combined.isNotEmpty) return combined;
    if (email.trim().isNotEmpty) return email.trim();
    return phoneNumber;
  }

  factory ChatUserModel.fromJson(Map<String, dynamic> json) {
    return ChatUserModel(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      phoneNumber: (json['phone_number'] ?? '').toString(),
      isVerified: json['is_verified'] == true,
      role: (json['role'] ?? 'customer').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'is_verified': isVerified,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
