part of 'doctor_booking_bloc.dart';

@immutable
sealed class DoctorBookingState {}

final class DoctorBookingInitial extends DoctorBookingState {}

class DoctorBookingLoadingState extends DoctorBookingState {}

class DoctorBookingLoadedState extends DoctorBookingState {
  final ProviderProfileModel provider;
  final List<OfferingModel> offerings;
  final OfferingModel? selectedOffering;
  final String selectedDate;
  final bool isSlotsLoading;
  final List<AvailableSlotModel> slots;
  final String? slotsError;

  DoctorBookingLoadedState({
    required this.provider,
    required this.offerings,
    required this.selectedOffering,
    required this.selectedDate,
    required this.isSlotsLoading,
    required this.slots,
    this.slotsError,
  });

  OfferingModel? get inPersonOffering {
    try {
      return offerings.firstWhere((o) => o.visitMode == VisitModeType.inPerson);
    } catch (_) {
      return null;
    }
  }

  OfferingModel? get onlineChatOffering {
    try {
      return offerings.firstWhere(
        (o) => o.visitMode == VisitModeType.onlineChat,
      );
    } catch (_) {
      return null;
    }
  }

  bool get hasBothVisitModes =>
      inPersonOffering != null && onlineChatOffering != null;

  DoctorBookingLoadedState copyWith({
    ProviderProfileModel? provider,
    List<OfferingModel>? offerings,
    OfferingModel? selectedOffering,
    String? selectedDate,
    bool? isSlotsLoading,
    List<AvailableSlotModel>? slots,
    String? slotsError,
    bool clearSlotsError = false,
  }) {
    return DoctorBookingLoadedState(
      provider: provider ?? this.provider,
      offerings: offerings ?? this.offerings,
      selectedOffering: selectedOffering ?? this.selectedOffering,
      selectedDate: selectedDate ?? this.selectedDate,
      isSlotsLoading: isSlotsLoading ?? this.isSlotsLoading,
      slots: slots ?? this.slots,
      slotsError: clearSlotsError ? null : (slotsError ?? this.slotsError),
    );
  }
}

class DoctorBookingFailedState extends DoctorBookingState {
  final String message;

  DoctorBookingFailedState({required this.message});
}
