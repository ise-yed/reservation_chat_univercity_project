part of 'appointments_bloc.dart';

@immutable
sealed class AppointmentsState {}

final class AppointmentsInitial extends AppointmentsState {}

// --- لیست نوبت‌ها ---
class AppointmentsListLoadingState extends AppointmentsState {}

class AppointmentsListSuccessState extends AppointmentsState {
  final List<AppointmentModel> appointments;
  final String? activeProviderId;

  AppointmentsListSuccessState({
    required this.appointments,
    this.activeProviderId,
  });
}

class AppointmentsListFailedState extends AppointmentsState {
  final String message;

  AppointmentsListFailedState({required this.message});
}

// --- ثبت نوبت جدید ---
class CreateAppointmentLoadingState extends AppointmentsState {}

class CreateAppointmentSuccessState extends AppointmentsState {
  final AppointmentModel appointment;

  CreateAppointmentSuccessState({required this.appointment});
}

class CreateAppointmentFailedState extends AppointmentsState {
  final String message;

  CreateAppointmentFailedState({required this.message});
}

// --- عملیات روی کارت نوبت (لغو، تایید، تکمیل، پرداخت) ---
class AppointmentActionLoadingState extends AppointmentsState {
  final String targetId;

  AppointmentActionLoadingState({required this.targetId});
}

class AppointmentActionSuccessState extends AppointmentsState {
  final String message;
  final String? payUrl;
  final String? paymentId;

  AppointmentActionSuccessState({
    required this.message,
    this.payUrl,
    this.paymentId,
  });
}

class AppointmentActionFailedState extends AppointmentsState {
  final String message;

  AppointmentActionFailedState({required this.message});
}
