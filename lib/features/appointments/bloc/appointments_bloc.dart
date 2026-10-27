import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:reservation_chat_univercity_project/core/utils/app_error.dart';
import 'package:reservation_chat_univercity_project/features/appointments/service/appointment_service.dart';
import 'package:reservation_chat_univercity_project/features/appointments/service/model/appointment_models.dart';

part 'appointments_event.dart';
part 'appointments_state.dart';

class AppointmentsBloc extends Bloc<AppointmentsEvent, AppointmentsState> {
  final AppointmentServices appointmentServices;
  String? _cachedProviderId;

  AppointmentsBloc([AppointmentServices? services])
    : appointmentServices = services ?? AppointmentServices(),
      super(AppointmentsInitial()) {
    on<FetchAppointmentsListEvent>(_onFetchAppointmentsList);
    on<CreateAppointmentBookingEvent>(_onCreateAppointmentBooking);
    on<CancelAppointmentEvent>(_onCancelAppointment);
    on<ConfirmAppointmentByDoctorEvent>(_onConfirmAppointmentByDoctor);
    on<CompleteOnlineVisitByDoctorEvent>(_onCompleteOnlineVisitByDoctor);
    on<MarkInPersonPaymentPaidEvent>(_onMarkInPersonPaymentPaid);
    on<RetryOnlinePaymentEvent>(_onRetryOnlinePayment);
  }

  Future<void> _onFetchAppointmentsList(
    FetchAppointmentsListEvent event,
    Emitter<AppointmentsState> emit,
  ) async {
    emit(AppointmentsListLoadingState());

    try {
      if (event.isProviderRole) {
        if (_cachedProviderId == null || _cachedProviderId!.isEmpty) {
          final myProfiles = await appointmentServices.getMyProviderProfiles();
          if (myProfiles.isEmpty) {
            emit(
              AppointmentsListSuccessState(
                appointments: const [],
                activeProviderId: null,
              ),
            );
            return;
          }
          _cachedProviderId = myProfiles.first.id;
        }

        final response = await appointmentServices.getProviderAppointments(
          providerId: _cachedProviderId!,
          page: 1,
          pageSize: 100,
        );

        emit(
          AppointmentsListSuccessState(
            appointments: response.results,
            activeProviderId: _cachedProviderId,
          ),
        );
      } else {
        final response = await appointmentServices.getMyAppointments(
          page: 1,
          pageSize: 100,
        );

        emit(AppointmentsListSuccessState(appointments: response.results));
      }
    } catch (e) {
      emit(AppointmentsListFailedState(message: _errMsg(e)));
    }
  }

  Future<void> _onCreateAppointmentBooking(
    CreateAppointmentBookingEvent event,
    Emitter<AppointmentsState> emit,
  ) async {
    emit(CreateAppointmentLoadingState());

    try {
      final created = await appointmentServices.createAppointment(
        providerId: event.providerId,
        offeringId: event.offeringId,
        startAt: event.startAt,
        paymentMethod: event.paymentMethod,
        notes: event.notes,
      );

      emit(CreateAppointmentSuccessState(appointment: created));
    } catch (e) {
      emit(CreateAppointmentFailedState(message: _errMsg(e)));
    }
  }

  Future<void> _onCancelAppointment(
    CancelAppointmentEvent event,
    Emitter<AppointmentsState> emit,
  ) async {
    emit(AppointmentActionLoadingState(targetId: event.appointmentId));

    try {
      await appointmentServices.cancelAppointment(
        appointmentId: event.appointmentId,
        cancelReason: event.cancelReason,
      );

      emit(AppointmentActionSuccessState(message: 'نوبت با موفقیت لغو شد.'));
      add(FetchAppointmentsListEvent(isProviderRole: event.isProviderRole));
    } catch (e) {
      emit(AppointmentActionFailedState(message: _errMsg(e)));
      add(FetchAppointmentsListEvent(isProviderRole: event.isProviderRole));
    }
  }

  Future<void> _onConfirmAppointmentByDoctor(
    ConfirmAppointmentByDoctorEvent event,
    Emitter<AppointmentsState> emit,
  ) async {
    emit(AppointmentActionLoadingState(targetId: event.appointmentId));

    try {
      await appointmentServices.updateAppointmentStatus(
        appointmentId: event.appointmentId,
        status: 'confirmed',
      );

      emit(
        AppointmentActionSuccessState(
          message: 'نوبت بیمار با موفقیت تأیید شد.',
        ),
      );
      add(FetchAppointmentsListEvent(isProviderRole: true));
    } catch (e) {
      emit(AppointmentActionFailedState(message: _errMsg(e)));
      add(FetchAppointmentsListEvent(isProviderRole: true));
    }
  }

  Future<void> _onCompleteOnlineVisitByDoctor(
    CompleteOnlineVisitByDoctorEvent event,
    Emitter<AppointmentsState> emit,
  ) async {
    emit(AppointmentActionLoadingState(targetId: event.appointmentId));

    try {
      await appointmentServices.completeOnlineVisit(
        appointmentId: event.appointmentId,
      );

      emit(
        AppointmentActionSuccessState(
          message: 'ویزیت آنلاین با موفقیت خاتمه یافت.',
        ),
      );
      add(FetchAppointmentsListEvent(isProviderRole: true));
    } catch (e) {
      emit(AppointmentActionFailedState(message: _errMsg(e)));
      add(FetchAppointmentsListEvent(isProviderRole: true));
    }
  }

  Future<void> _onMarkInPersonPaymentPaid(
    MarkInPersonPaymentPaidEvent event,
    Emitter<AppointmentsState> emit,
  ) async {
    emit(AppointmentActionLoadingState(targetId: event.paymentId));

    try {
      await appointmentServices.markPaidInPerson(paymentId: event.paymentId);

      emit(
        AppointmentActionSuccessState(
          message: 'پرداخت حضوری بیمار در مطب ثبت شد.',
        ),
      );
      add(FetchAppointmentsListEvent(isProviderRole: true));
    } catch (e) {
      emit(AppointmentActionFailedState(message: _errMsg(e)));
      add(FetchAppointmentsListEvent(isProviderRole: true));
    }
  }

  Future<void> _onRetryOnlinePayment(
    RetryOnlinePaymentEvent event,
    Emitter<AppointmentsState> emit,
  ) async {
    emit(AppointmentActionLoadingState(targetId: event.paymentId));

    try {
      final payment = await appointmentServices.startOnlinePayment(
        paymentId: event.paymentId,
      );

      emit(
        AppointmentActionSuccessState(
          message: 'درگاه پرداخت آماده شد.',
          payUrl: payment.payUrl,
          paymentId: payment.id,
        ),
      );
      add(FetchAppointmentsListEvent(isProviderRole: false));
    } catch (e) {
      emit(AppointmentActionFailedState(message: _errMsg(e)));
      add(FetchAppointmentsListEvent(isProviderRole: false));
    }
  }

  String _errMsg(Object e) => getAppErrorMessage(e);
}
