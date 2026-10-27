part of 'doctor_booking_bloc.dart';

@immutable
sealed class DoctorBookingEvent {}

class LoadProviderAndOfferingsEvent extends DoctorBookingEvent {
  final String providerId;
  final String initialDate;

  LoadProviderAndOfferingsEvent({
    required this.providerId,
    required this.initialDate,
  });
}

class SelectVisitModeOfferingEvent extends DoctorBookingEvent {
  final OfferingModel offering;
  final String date;

  SelectVisitModeOfferingEvent({required this.offering, required this.date});
}

class SelectBookingDateEvent extends DoctorBookingEvent {
  final String date;

  SelectBookingDateEvent({required this.date});
}
