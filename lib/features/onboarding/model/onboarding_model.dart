import 'package:reservation_chat_univercity_project/core/constants/app_constants.dart';

class OnboardingModel {
  final String id;
  final String image;
  final String title;
  final String summary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  OnboardingModel({
    required this.id,
    required this.image,
    required this.title,
    required this.summary,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory OnboardingModel.fromJson(Map<String, dynamic> json) {
    return OnboardingModel(
      id: (json['_id'] ?? '') as String,
      image: '${AppConstants.appImgBaseUrl}${(json['image'] ?? '') as String}',
      title: (json['title'] ?? '') as String,
      summary: (json['summary'] ?? '') as String,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      v: (json['__v'] ?? 0) is int
          ? json['__v'] as int
          : int.tryParse(json['__v']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // '_id': id,
      'image': image,
      'title': title,
      'summary': summary,
      // 'createdAt': createdAt.toIso8601String(),
      // 'updatedAt': updatedAt.toIso8601String(),
      // '__v': v,
    };
  }

  static List<OnboardingModel> listFromJson(dynamic json) {
    final List<dynamic>? rawList = json is List
        ? json
        : (json is Map<String, dynamic> && json['results'] is List)
        ? json['results'] as List
        : null;

    if (rawList == null) return <OnboardingModel>[];
    return rawList
        .map(
          (e) => OnboardingModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
}
