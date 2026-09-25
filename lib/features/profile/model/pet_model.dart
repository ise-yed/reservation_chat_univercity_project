import 'package:flutter/foundation.dart';

@immutable
class PetModel {
  final String id;
  final String name;
  final String? petId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  const PetModel({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.petId,
  });

  bool get isBreed => petId != null;

  bool get isPet => petId == null;

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      petId: json['pet'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      v: (json['__v'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, if (petId != null) 'pet': petId};
  }

  static const _sentinel = Object();

  PetModel copyWith({
    String? id,
    String? name,
    Object? petId = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
  }) {
    return PetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      petId: identical(petId, _sentinel) ? this.petId : petId as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
    );
  }

  static List<PetModel> listFromJson(List<dynamic> list) => list
      .map((e) => PetModel.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);

  @override
  String toString() =>
      'CatalogItem(id: $id, name: $name, petId: $petId, createdAt: $createdAt, updatedAt: $updatedAt, v: $v)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          petId == other.petId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          v == other.v;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      (petId?.hashCode ?? 0) ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      v.hashCode;
}
