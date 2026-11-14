part of 'provider_services_bloc.dart';

/// Immutable snapshot of the active provider workspace for "خدمات من".
class ProviderServicesData {
  final List<ProviderProfileModel> profiles;
  final ProviderProfileModel selectedProfile;
  final List<MyOrganizationModel> ownedOrganizations;
  final bool canManageOfferings;
  final List<ProviderOfferingModel> offerings;
  final List<WorkingHourModel> workingHours;
  final List<TimeOffModel> timeOffs;
  final List<CategoryModel> categories;

  const ProviderServicesData({
    required this.profiles,
    required this.selectedProfile,
    required this.ownedOrganizations,
    required this.canManageOfferings,
    required this.offerings,
    required this.workingHours,
    required this.timeOffs,
    required this.categories,
  });

  ProviderServicesData copyWith({
    List<ProviderProfileModel>? profiles,
    ProviderProfileModel? selectedProfile,
    List<MyOrganizationModel>? ownedOrganizations,
    bool? canManageOfferings,
    List<ProviderOfferingModel>? offerings,
    List<WorkingHourModel>? workingHours,
    List<TimeOffModel>? timeOffs,
    List<CategoryModel>? categories,
  }) {
    return ProviderServicesData(
      profiles: profiles ?? this.profiles,
      selectedProfile: selectedProfile ?? this.selectedProfile,
      ownedOrganizations: ownedOrganizations ?? this.ownedOrganizations,
      canManageOfferings: canManageOfferings ?? this.canManageOfferings,
      offerings: offerings ?? this.offerings,
      workingHours: workingHours ?? this.workingHours,
      timeOffs: timeOffs ?? this.timeOffs,
      categories: categories ?? this.categories,
    );
  }
}

@immutable
sealed class ProviderServicesState {
  const ProviderServicesState();

  ProviderServicesData? get dataOrNull => switch (this) {
    ProviderServicesLoaded(data: final d) => d,
    ProviderServiceActionLoading(data: final d) => d,
    ProviderServiceActionSuccess(data: final d) => d,
    ProviderServiceActionError(data: final d) => d,
    _ => null,
  };
}

final class ProviderServicesInitial extends ProviderServicesState {
  const ProviderServicesInitial();
}

final class ProviderServicesLoading extends ProviderServicesState {
  const ProviderServicesLoading();
}

final class ProviderServicesEmptyProfile extends ProviderServicesState {
  const ProviderServicesEmptyProfile();
}

final class ProviderServicesLoaded extends ProviderServicesState {
  final ProviderServicesData data;

  const ProviderServicesLoaded({required this.data});
}

final class ProviderServicesError extends ProviderServicesState {
  final String message;

  const ProviderServicesError({required this.message});
}

final class ProviderServiceActionLoading extends ProviderServicesState {
  final ProviderServicesData data;
  final String? targetId;

  const ProviderServiceActionLoading({
    required this.data,
    this.targetId,
  });
}

final class ProviderServiceActionSuccess extends ProviderServicesState {
  final ProviderServicesData data;
  final String message;

  const ProviderServiceActionSuccess({
    required this.data,
    required this.message,
  });
}

final class ProviderServiceActionError extends ProviderServicesState {
  final ProviderServicesData data;
  final String message;

  const ProviderServiceActionError({
    required this.data,
    required this.message,
  });
}

