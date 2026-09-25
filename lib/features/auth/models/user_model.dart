class UserModel {
  String? id;
  String? email;
  String? firstName;
  String? lastName;
  String? fullName;
  bool? isVerified;
  String? role;
  
  String? avatar;
  String? name;
  String? phoneNumber;
  String? petName;
  String? pet;
  String? petBreed;
  int? petAge;
  String? petSex;
  String? address;
  String? firebaseToken;
  DateTime? subscriptionPurchaseDate;
  DateTime? subscriptionExpireDate;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? petBirthDay;

  UserModel({
    this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.fullName,
    this.isVerified,
    this.role,
    this.avatar,
    this.name,
    this.phoneNumber,
    this.petName,
    this.pet,
    this.petBreed,
    this.petAge,
    this.petSex,
    this.address,
    this.firebaseToken,
    this.subscriptionPurchaseDate,
    this.subscriptionExpireDate,
    this.createdAt,
    this.updatedAt,
    this.petBirthDay,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id'],
      email: json['email'],
      firstName: json['first_name'] ?? json['firstName'],
      lastName: json['last_name'] ?? json['lastName'],
      fullName: json['full_name'] ?? json['fullName'],
      isVerified: json['is_verified'] ?? json['isVerified'],
      role: json['role'],
      avatar: json['avatar'],
      name: json['full_name'] ?? json['name'],
      phoneNumber: json['phone_number'] ?? json['phoneNumber'],
      petName: json['petName'],
      pet: json['pet'],
      petBreed: json['petBreed'],
      petAge: json['petAge'],
      petSex: json['petSex'],
      address: json['address'],
      firebaseToken: json['firebaseToken'],
      subscriptionPurchaseDate: json['subscriptionPurchaseDate'] != null
          ? DateTime.tryParse(json['subscriptionPurchaseDate'])
          : null,
      subscriptionExpireDate: json['subscriptionExpireDate'] != null
          ? DateTime.tryParse(json['subscriptionExpireDate'])
          : null,
      createdAt: (json['created_at'] != null)
          ? DateTime.tryParse(json['created_at'])
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])
              : null),
      updatedAt: (json['updated_at'] != null)
          ? DateTime.tryParse(json['updated_at'])
          : (json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'])
              : null),
      petBirthDay: json['petBirthDay'] != null
          ? DateTime.tryParse(json['petBirthDay'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'is_verified': isVerified,
      'role': role,
      'avatar': avatar,
      'name': name,
      'phoneNumber': phoneNumber,
      'petName': petName,
      'pet': pet,
      'petBreed': petBreed,
      'petAge': petAge ?? 0,
      'petSex': petSex,
      'address': address,
      'firebaseToken': firebaseToken,
      'subscriptionPurchaseDate': subscriptionPurchaseDate?.toIso8601String(),
      'subscriptionExpireDate': subscriptionExpireDate?.toIso8601String(),
      // 'createdAt': createdAt?.toIso8601String(),
      // 'updatedAt': updatedAt?.toIso8601String(),
      'petBirthDay': petBirthDay?.toIso8601String(),
    };
  }
}
