import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? icon;
  final String? description;
  final String? color;
  final String? parent;
  final List<CategoryModel> children;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.description,
    this.color,
    this.parent,
    this.children = const [],
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      icon: json['icon']?.toString(),
      description: json['description']?.toString(),
      color: json['color']?.toString(),
      parent: json['parent']?.toString(),
      children: json['children'] is List
          ? List<CategoryModel>.from(
              (json['children'] as List).map(
                (x) => CategoryModel.fromJson(Map<String, dynamic>.from(x)),
              ),
            )
          : const [],
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  IconData get resolvedIcon {
    final key = '${slug.toLowerCase()} ${name.toLowerCase()} ${icon ?? ''}';
    if (key.contains('cardio') ||
        key.contains('heart') ||
        key.contains('قلب')) {
      return Icons.monitor_heart_rounded;
    }
    if (key.contains('derma') || key.contains('skin') || key.contains('پوست')) {
      return Icons.face_retouching_natural_rounded;
    }
    if (key.contains('neuro') || key.contains('brain') || key.contains('مغز')) {
      return Icons.psychology_rounded;
    }
    if (key.contains('pedia') ||
        key.contains('child') ||
        key.contains('کودک')) {
      return Icons.child_care_rounded;
    }
    if (key.contains('obgyn') ||
        key.contains('women') ||
        key.contains('زنان')) {
      return Icons.pregnant_woman_rounded;
    }
    if (key.contains('ortho') ||
        key.contains('bone') ||
        key.contains('ارتوپد')) {
      return Icons.accessibility_new_rounded;
    }
    if (key.contains('ophtha') || key.contains('eye') || key.contains('چشم')) {
      return Icons.visibility_rounded;
    }
    if (key.contains('dent') ||
        key.contains('tooth') ||
        key.contains('دندان')) {
      return Icons.medical_services_rounded;
    }
    return Icons.local_hospital_rounded;
  }
}

class ProviderUserInlineModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String phoneNumber;
  final bool isVerified;
  final String role;

  ProviderUserInlineModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.phoneNumber,
    required this.isVerified,
    required this.role,
  });

  factory ProviderUserInlineModel.fromJson(Map<String, dynamic> json) {
    final fName = json['first_name']?.toString() ?? '';
    final lName = json['last_name']?.toString() ?? '';
    final combined = '$fName $lName'.trim();
    final full = json['full_name']?.toString().trim();

    return ProviderUserInlineModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: fName,
      lastName: lName,
      fullName: (full != null && full.isNotEmpty)
          ? full
          : (combined.isNotEmpty
                ? combined
                : (json['email']?.toString() ?? '')),
      phoneNumber: json['phone_number']?.toString() ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
      role: json['role']?.toString() ?? 'provider',
    );
  }
}

class ProviderOrganizationInlineModel {
  final String id;
  final String name;
  final String slug;

  ProviderOrganizationInlineModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory ProviderOrganizationInlineModel.fromJson(Map<String, dynamic> json) {
    return ProviderOrganizationInlineModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }
}

class ProviderBranchInlineModel {
  final String id;
  final String name;
  final String address;
  final String phoneNumber;

  ProviderBranchInlineModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phoneNumber,
  });

  factory ProviderBranchInlineModel.fromJson(Map<String, dynamic> json) {
    return ProviderBranchInlineModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
    );
  }
}

class ProviderSpecialtyInlineModel {
  final String id;
  final String name;
  final String slug;

  ProviderSpecialtyInlineModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory ProviderSpecialtyInlineModel.fromJson(Map<String, dynamic> json) {
    return ProviderSpecialtyInlineModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }
}

class ProviderProfileModel {
  final String id;
  final ProviderUserInlineModel user;
  final ProviderOrganizationInlineModel organization;
  final ProviderBranchInlineModel? branch;
  final String title;
  final List<ProviderSpecialtyInlineModel> specialties;
  final String bio;
  final int defaultSlotDurationMinutes;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  ProviderProfileModel({
    required this.id,
    required this.user,
    required this.organization,
    this.branch,
    required this.title,
    required this.specialties,
    required this.bio,
    required this.defaultSlotDurationMinutes,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory ProviderProfileModel.fromJson(Map<String, dynamic> json) {
    return ProviderProfileModel(
      id: json['id']?.toString() ?? '',
      user: ProviderUserInlineModel.fromJson(
        json['user'] is Map
            ? Map<String, dynamic>.from(json['user'])
            : <String, dynamic>{},
      ),
      organization: ProviderOrganizationInlineModel.fromJson(
        json['organization'] is Map
            ? Map<String, dynamic>.from(json['organization'])
            : <String, dynamic>{},
      ),
      branch: json['branch'] is Map
          ? ProviderBranchInlineModel.fromJson(
              Map<String, dynamic>.from(json['branch']),
            )
          : null,
      title: json['title']?.toString() ?? '',
      specialties: json['specialties'] is List
          ? List<ProviderSpecialtyInlineModel>.from(
              (json['specialties'] as List).map(
                (x) => ProviderSpecialtyInlineModel.fromJson(
                  Map<String, dynamic>.from(x),
                ),
              ),
            )
          : const [],
      bio: json['bio']?.toString() ?? '',
      defaultSlotDurationMinutes:
          (json['default_slot_duration_minutes'] as num?)?.toInt() ?? 30,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  String get displayName {
    final rawName = user.fullName.trim();
    final rawTitle = title.trim();
    if (rawTitle.isEmpty) return rawName;
    if (rawName.startsWith(rawTitle)) return rawName;
    return '$rawTitle $rawName'.trim();
  }

  String get specialtiesTitle {
    if (specialties.isNotEmpty) {
      return specialties.map((s) => s.name).join('، ');
    }
    if (title.trim().isNotEmpty) {
      return title.trim();
    }
    return 'پزشک متخصص';
  }

  String get clinicDisplayTitle {
    if (branch != null && branch!.name.trim().isNotEmpty) {
      return '${organization.name} (${branch!.name})';
    }
    return organization.name;
  }

  String get clinicAddressDisplay {
    if (branch != null && branch!.address.trim().isNotEmpty) {
      return branch!.address.trim();
    }
    return organization.name;
  }
}

class PaginatedProvidersResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<ProviderProfileModel> results;
  final int page;

  PaginatedProvidersResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
    required this.page,
  });

  bool get hasNextPage => next != null && next!.isNotEmpty;
  int? get nextPage => hasNextPage ? page + 1 : null;

  factory PaginatedProvidersResponse.fromJson(
    dynamic json, {
    required int currentPage,
  }) {
    if (json is Map<String, dynamic>) {
      final list = json['results'] is List
          ? List<ProviderProfileModel>.from(
              (json['results'] as List).map(
                (x) =>
                    ProviderProfileModel.fromJson(Map<String, dynamic>.from(x)),
              ),
            )
          : <ProviderProfileModel>[];
      return PaginatedProvidersResponse(
        count: (json['count'] as num?)?.toInt() ?? list.length,
        next: json['next']?.toString(),
        previous: json['previous']?.toString(),
        results: list,
        page: currentPage,
      );
    }
    if (json is List) {
      final list = List<ProviderProfileModel>.from(
        json.map(
          (x) => ProviderProfileModel.fromJson(Map<String, dynamic>.from(x)),
        ),
      );
      return PaginatedProvidersResponse(
        count: list.length,
        next: null,
        previous: null,
        results: list,
        page: currentPage,
      );
    }
    return PaginatedProvidersResponse(
      count: 0,
      results: const [],
      page: currentPage,
    );
  }
}
