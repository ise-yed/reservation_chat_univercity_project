part of 'provider_services_bloc.dart';

@immutable
sealed class ProviderServicesEvent {}

class LoadProviderServicesEvent extends ProviderServicesEvent {
  final String? selectedProviderId;
  final bool silent;

  LoadProviderServicesEvent({
    this.selectedProviderId,
    this.silent = false,
  });
}

class SelectProviderProfileEvent extends ProviderServicesEvent {
  final String providerId;

  SelectProviderProfileEvent({required this.providerId});
}

class CreateOfferingEvent extends ProviderServicesEvent {
  final OfferingFormPayload payload;

  CreateOfferingEvent({required this.payload});
}

class UpdateOfferingEvent extends ProviderServicesEvent {
  final String offeringId;
  final OfferingFormPayload payload;

  UpdateOfferingEvent({
    required this.offeringId,
    required this.payload,
  });
}

class ToggleOfferingStatusEvent extends ProviderServicesEvent {
  final ProviderOfferingModel offering;
  final bool isActive;

  ToggleOfferingStatusEvent({
    required this.offering,
    required this.isActive,
  });
}

class CreateWorkingHourEvent extends ProviderServicesEvent {
  final int weekday;
  final String startTime;
  final String endTime;
  final bool isActive;

  CreateWorkingHourEvent({
    required this.weekday,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });
}

class UpdateWorkingHourEvent extends ProviderServicesEvent {
  final String workingHourId;
  final int weekday;
  final String startTime;
  final String endTime;
  final bool isActive;

  UpdateWorkingHourEvent({
    required this.workingHourId,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });
}

class ToggleWorkingHourStatusEvent extends ProviderServicesEvent {
  final WorkingHourModel workingHour;
  final bool isActive;

  ToggleWorkingHourStatusEvent({
    required this.workingHour,
    required this.isActive,
  });
}

class CreateTimeOffEvent extends ProviderServicesEvent {
  final DateTime startAt;
  final DateTime endAt;
  final String reason;
  final bool isActive;

  CreateTimeOffEvent({
    required this.startAt,
    required this.endAt,
    this.reason = '',
    this.isActive = true,
  });
}

class UpdateTimeOffEvent extends ProviderServicesEvent {
  final String timeOffId;
  final DateTime startAt;
  final DateTime endAt;
  final String reason;
  final bool isActive;

  UpdateTimeOffEvent({
    required this.timeOffId,
    required this.startAt,
    required this.endAt,
    this.reason = '',
    required this.isActive,
  });
}

class ToggleTimeOffStatusEvent extends ProviderServicesEvent {
  final TimeOffModel timeOff;
  final bool isActive;

  ToggleTimeOffStatusEvent({
    required this.timeOff,
    required this.isActive,
  });
}

class UpdateProviderScheduleSettingsEvent extends ProviderServicesEvent {
  final String title;
  final String bio;
  final int defaultSlotDurationMinutes;

  UpdateProviderScheduleSettingsEvent({
    required this.title,
    required this.bio,
    required this.defaultSlotDurationMinutes,
  });
}

