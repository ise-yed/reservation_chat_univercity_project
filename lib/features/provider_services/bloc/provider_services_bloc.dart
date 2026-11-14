import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reservation_chat_univercity_project/core/utils/app_error.dart';
import 'package:reservation_chat_univercity_project/features/home/services/model/home_models.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/service/model/provider_services_models.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/service/provider_services_service.dart';

part 'provider_services_event.dart';
part 'provider_services_state.dart';

class ProviderServicesBloc
    extends Bloc<ProviderServicesEvent, ProviderServicesState> {
  final ProviderServicesService _service;

  ProviderServicesBloc([ProviderServicesService? service])
    : _service = service ?? ProviderServicesService(),
      super(const ProviderServicesInitial()) {
    on<LoadProviderServicesEvent>(_onLoad);
    on<SelectProviderProfileEvent>(_onSelectProfile);
    on<CreateOfferingEvent>(_onCreateOffering);
    on<UpdateOfferingEvent>(_onUpdateOffering);
    on<ToggleOfferingStatusEvent>(_onToggleOfferingStatus);
    on<CreateWorkingHourEvent>(_onCreateWorkingHour);
    on<UpdateWorkingHourEvent>(_onUpdateWorkingHour);
    on<ToggleWorkingHourStatusEvent>(_onToggleWorkingHourStatus);
    on<CreateTimeOffEvent>(_onCreateTimeOff);
    on<UpdateTimeOffEvent>(_onUpdateTimeOff);
    on<ToggleTimeOffStatusEvent>(_onToggleTimeOffStatus);
    on<UpdateProviderScheduleSettingsEvent>(_onUpdateProviderSettings);
  }

  Future<void> _onLoad(
    LoadProviderServicesEvent event,
    Emitter<ProviderServicesState> emit,
  ) async {
    final previousData = state.dataOrNull;
    if (previousData == null && !event.silent) {
      emit(const ProviderServicesLoading());
    }

    try {
      final profiles = await _service.getMyProviderProfiles();
      if (profiles.isEmpty) {
        emit(const ProviderServicesEmptyProfile());
        return;
      }

      final preferredId =
          event.selectedProviderId ?? previousData?.selectedProfile.id;
      final selectedProfile = _resolveSelectedProfile(profiles, preferredId);

      final data = await _fetchWorkspaceData(
        profiles: profiles,
        selectedProfile: selectedProfile,
        cachedCategories: previousData?.categories,
      );
      emit(ProviderServicesLoaded(data: data));
    } catch (e) {
      final msg = getAppErrorMessage(e);
      if (previousData != null) {
        emit(ProviderServiceActionError(data: previousData, message: msg));
      } else {
        emit(ProviderServicesError(message: msg));
      }
    }
  }

  Future<void> _onSelectProfile(
    SelectProviderProfileEvent event,
    Emitter<ProviderServicesState> emit,
  ) async {
    final current = state.dataOrNull;
    if (current == null || current.selectedProfile.id == event.providerId) {
      return;
    }

    final targetProfile = _resolveSelectedProfile(
      current.profiles,
      event.providerId,
    );

    emit(
      ProviderServiceActionLoading(
        data: current,
        targetId: 'profile:${targetProfile.id}',
      ),
    );

    try {
      final data = await _fetchWorkspaceData(
        profiles: current.profiles,
        selectedProfile: targetProfile,
        cachedOwnedOrganizations: current.ownedOrganizations,
        cachedCategories: current.categories,
      );
      emit(ProviderServicesLoaded(data: data));
    } catch (e) {
      emit(
        ProviderServiceActionError(
          data: current,
          message: getAppErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onCreateOffering(
    CreateOfferingEvent event,
    Emitter<ProviderServicesState> emit,
  ) {
    return _runMutation(
      emit,
      targetId: 'create_offering',
      successMessage: 'خدمت جدید با موفقیت ثبت شد.',
      action: (current) async {
        final created = await _service.createOffering(
          organizationId: current.selectedProfile.organization.id,
          providerId: current.selectedProfile.id,
          payload: event.payload,
        );
        final updatedList = _sortOfferings([created, ...current.offerings]);
        return current.copyWith(offerings: updatedList);
      },
    );
  }

  Future<void> _onUpdateOffering(
    UpdateOfferingEvent event,
    Emitter<ProviderServicesState> emit,
  ) {
    return _runMutation(
      emit,
      targetId: event.offeringId,
      successMessage: 'اطلاعات خدمت با موفقیت بروزرسانی شد.',
      action: (current) async {
        final updated = await _service.updateOffering(
          offeringId: event.offeringId,
          data: event.payload.toUpdateJson(),
        );
        final updatedList = _sortOfferings(
          _replaceById(current.offerings, updated, (o) => o.id),
        );
        return current.copyWith(offerings: updatedList);
      },
    );
  }

  Future<void> _onToggleOfferingStatus(
    ToggleOfferingStatusEvent event,
    Emitter<ProviderServicesState> emit,
  ) {
    final label = event.isActive ? 'فعال' : 'غیرفعال';
    return _runMutation(
      emit,
      targetId: event.offering.id,
      successMessage: 'خدمت «${event.offering.title}» $label شد.',
      action: (current) async {
        final updated = await _service.updateOffering(
          offeringId: event.offering.id,
          data: {'is_active': event.isActive},
        );
        final updatedList = _sortOfferings(
          _replaceById(current.offerings, updated, (o) => o.id),
        );
        return current.copyWith(offerings: updatedList);
      },
    );
  }

  Future<void> _onCreateWorkingHour(
    CreateWorkingHourEvent event,
    Emitter<ProviderServicesState> emit,
  ) {
    return _runMutation(
      emit,
      targetId: 'create_working_hour',
      successMessage: 'ساعت کاری جدید با موفقیت ثبت شد.',
      action: (current) async {
        final created = await _service.createWorkingHour(
          providerId: current.selectedProfile.id,
          weekday: event.weekday,
          startTime: event.startTime,
          endTime: event.endTime,
          isActive: event.isActive,
        );
        final list = [...current.workingHours, created]
          ..sort(WorkingHourModel.compareForSchedule);
        return current.copyWith(workingHours: list);
      },
    );
  }

  Future<void> _onUpdateWorkingHour(
    UpdateWorkingHourEvent event,
    Emitter<ProviderServicesState> emit,
  ) {
    return _runMutation(
      emit,
      targetId: event.workingHourId,
      successMessage: 'ساعت کاری با موفقیت بروزرسانی شد.',
      action: (current) async {
        final updated = await _service.updateWorkingHour(
          workingHourId: event.workingHourId,
          data: {
            'weekday': event.weekday,
            'start_time': event.startTime,
            'end_time': event.endTime,
            'is_active': event.isActive,
          },
        );
        final list = _replaceById(current.workingHours, updated, (w) => w.id)
          ..sort(WorkingHourModel.compareForSchedule);
        return current.copyWith(workingHours: list);
      },
    );
  }

  Future<void> _onToggleWorkingHourStatus(
    ToggleWorkingHourStatusEvent event,
    Emitter<ProviderServicesState> emit,
  ) {
    final label = event.isActive ? 'فعال' : 'غیرفعال';
    return _runMutation(
      emit,
      targetId: event.workingHour.id,
      successMessage:
          'ساعت کاری روز ${event.workingHour.persianWeekdayName} $label شد.',
      action: (current) async {
        final updated = await _service.updateWorkingHour(
          workingHourId: event.workingHour.id,
          data: {'is_active': event.isActive},
        );
        final list = _replaceById(current.workingHours, updated, (w) => w.id)
          ..sort(WorkingHourModel.compareForSchedule);
        return current.copyWith(workingHours: list);
      },
    );
  }

  Future<void> _onCreateTimeOff(
    CreateTimeOffEvent event,
    Emitter<ProviderServicesState> emit,
  ) {
    return _runMutation(
      emit,
      targetId: 'create_time_off',
      successMessage: 'مرخصی جدید با موفقیت ثبت شد.',
      action: (current) async {
        final created = await _service.createTimeOff(
          providerId: current.selectedProfile.id,
          startAt: event.startAt,
          endAt: event.endAt,
          reason: event.reason,
          isActive: event.isActive,
        );
        final list = _sortTimeOffs([created, ...current.timeOffs]);
        return current.copyWith(timeOffs: list);
      },
    );
  }

  Future<void> _onUpdateTimeOff(
    UpdateTimeOffEvent event,
    Emitter<ProviderServicesState> emit,
  ) {
    return _runMutation(
      emit,
      targetId: event.timeOffId,
      successMessage: 'اطلاعات مرخصی بروزرسانی شد.',
      action: (current) async {
        final updated = await _service.updateTimeOff(
          timeOffId: event.timeOffId,
          data: {
            'start_at': event.startAt.toUtc().toIso8601String(),
            'end_at': event.endAt.toUtc().toIso8601String(),
            'reason': event.reason.trim(),
            'is_active': event.isActive,
          },
        );
        final list = _sortTimeOffs(
          _replaceById(current.timeOffs, updated, (t) => t.id),
        );
        return current.copyWith(timeOffs: list);
      },
    );
  }

  Future<void> _onToggleTimeOffStatus(
    ToggleTimeOffStatusEvent event,
    Emitter<ProviderServicesState> emit,
  ) {
    final label = event.isActive ? 'فعال' : 'لغو';
    return _runMutation(
      emit,
      targetId: event.timeOff.id,
      successMessage: 'بازه مرخصی با موفقیت $label شد.',
      action: (current) async {
        final updated = await _service.updateTimeOff(
          timeOffId: event.timeOff.id,
          data: {'is_active': event.isActive},
        );
        final list = _sortTimeOffs(
          _replaceById(current.timeOffs, updated, (t) => t.id),
        );
        return current.copyWith(timeOffs: list);
      },
    );
  }

  Future<void> _onUpdateProviderSettings(
    UpdateProviderScheduleSettingsEvent event,
    Emitter<ProviderServicesState> emit,
  ) {
    return _runMutation(
      emit,
      targetId: 'provider_settings',
      successMessage: 'تنظیمات پروفایل و زمان‌بندی بروزرسانی شد.',
      action: (current) async {
        final updatedProfile = await _service.updateProviderProfile(
          providerId: current.selectedProfile.id,
          title: event.title,
          bio: event.bio,
          defaultSlotDurationMinutes: event.defaultSlotDurationMinutes,
        );
        final updatedProfiles = _replaceById(
          current.profiles,
          updatedProfile,
          (p) => p.id,
        );
        return current.copyWith(
          profiles: updatedProfiles,
          selectedProfile: updatedProfile,
        );
      },
    );
  }

  Future<void> _runMutation(
    Emitter<ProviderServicesState> emit, {
    String? targetId,
    required String successMessage,
    required Future<ProviderServicesData> Function(ProviderServicesData current)
    action,
  }) async {
    final current = state.dataOrNull;
    if (current == null) return;

    emit(ProviderServiceActionLoading(data: current, targetId: targetId));
    try {
      final updated = await action(current);
      emit(
        ProviderServiceActionSuccess(data: updated, message: successMessage),
      );
    } catch (e) {
      emit(
        ProviderServiceActionError(
          data: current,
          message: getAppErrorMessage(e),
        ),
      );
    }
  }

  Future<ProviderServicesData> _fetchWorkspaceData({
    required List<ProviderProfileModel> profiles,
    required ProviderProfileModel selectedProfile,
    List<MyOrganizationModel>? cachedOwnedOrganizations,
    List<CategoryModel>? cachedCategories,
  }) async {
    final results = await Future.wait<dynamic>([
      cachedOwnedOrganizations != null
          ? Future.value(cachedOwnedOrganizations)
          : _safeGetMyOrganizations(),
      cachedCategories != null && cachedCategories.isNotEmpty
          ? Future.value(cachedCategories)
          : _safeGetCategories(),
      _service.getProviderOfferings(selectedProfile.id),
      _service.getProviderWorkingHours(selectedProfile.id),
      _service.getProviderTimeOffs(selectedProfile.id),
    ]);

    final ownedOrgs = results[0] as List<MyOrganizationModel>;
    final categories = results[1] as List<CategoryModel>;
    final offerings = _sortOfferings(results[2] as List<ProviderOfferingModel>);
    final workingHours = List<WorkingHourModel>.from(
      results[3] as List<WorkingHourModel>,
    )..sort(WorkingHourModel.compareForSchedule);
    final timeOffs = _sortTimeOffs(results[4] as List<TimeOffModel>);

    final canManageOfferings = ownedOrgs.any(
      (org) => org.id == selectedProfile.organization.id,
    );

    return ProviderServicesData(
      profiles: profiles,
      selectedProfile: selectedProfile,
      ownedOrganizations: ownedOrgs,
      canManageOfferings: canManageOfferings,
      offerings: offerings,
      workingHours: workingHours,
      timeOffs: timeOffs,
      categories: flattenCategories(categories),
    );
  }

  Future<List<MyOrganizationModel>> _safeGetMyOrganizations() async {
    try {
      return await _service.getMyOrganizations();
    } catch (_) {
      return const [];
    }
  }

  Future<List<CategoryModel>> _safeGetCategories() async {
    try {
      return await _service.getCategories();
    } catch (_) {
      return const [];
    }
  }

  static ProviderProfileModel _resolveSelectedProfile(
    List<ProviderProfileModel> profiles,
    String? preferredId,
  ) {
    if (preferredId != null) {
      for (final profile in profiles) {
        if (profile.id == preferredId) return profile;
      }
    }
    return profiles.first;
  }

  static List<T> _replaceById<T>(
    List<T> items,
    T updated,
    String Function(T) idOf,
  ) {
    final targetId = idOf(updated);
    return items.map((item) => idOf(item) == targetId ? updated : item).toList();
  }

  static List<ProviderOfferingModel> _sortOfferings(
    List<ProviderOfferingModel> list,
  ) {
    final sorted = List<ProviderOfferingModel>.from(list);
    sorted.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return a.title.compareTo(b.title);
    });
    return sorted;
  }

  static List<TimeOffModel> _sortTimeOffs(List<TimeOffModel> list) {
    final sorted = List<TimeOffModel>.from(list);
    sorted.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return b.startAt.compareTo(a.startAt);
    });
    return sorted;
  }
}
