part of 'appointments_bloc.dart';

@immutable
sealed class AppointmentsEvent {}

class FetchAppointmentsListEvent extends AppointmentsEvent {
  final bool isProviderRole;

  FetchAppointmentsListEvent({required this.isProviderRole});
}

class CreateAppointmentBookingEvent extends AppointmentsEvent {
  final String providerId;
  final String offeringId;
  final String startAt;
  final String paymentMethod;
  final String notes;

  CreateAppointmentBookingEvent({
    required this.providerId,
    required this.offeringId,
    required this.startAt,
    required this.paymentMethod,
    this.notes = '',
  });
}

class CancelAppointmentEvent extends AppointmentsEvent {
  final String appointmentId;
  final String cancelReason;
  final bool isProviderRole;

  CancelAppointmentEvent({
    required this.appointmentId,
    required this.cancelReason,
    required this.isProviderRole,
  });
}

class ConfirmAppointmentByDoctorEvent extends AppointmentsEvent {
  final String appointmentId;

  ConfirmAppointmentByDoctorEvent({required this.appointmentId});
}

class CompleteOnlineVisitByDoctorEvent extends AppointmentsEvent {
  final String appointmentId;

  CompleteOnlineVisitByDoctorEvent({required this.appointmentId});
}

class MarkInPersonPaymentPaidEvent extends AppointmentsEvent {
  final String paymentId;

  MarkInPersonPaymentPaidEvent({required this.paymentId});
}

class RetryOnlinePaymentEvent extends AppointmentsEvent {
  final String paymentId;

  RetryOnlinePaymentEvent({required this.paymentId});
}
