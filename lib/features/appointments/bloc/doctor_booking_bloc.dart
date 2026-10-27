import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:reservation_chat_univercity_project/core/utils/app_error.dart';
import 'package:reservation_chat_univercity_project/features/appointments/service/appointment_service.dart';
import 'package:reservation_chat_univercity_project/features/appointments/service/model/appointment_models.dart';

import 'package:reservation_chat_univercity_project/features/home/services/model/home_models.dart';

part 'doctor_booking_event.dart';
part 'doctor_booking_state.dart';

class DoctorBookingBloc extends Bloc<DoctorBookingEvent, DoctorBookingState> {
  final AppointmentServices appointmentServices;

  DoctorBookingBloc([AppointmentServices? services])
    : appointmentServices = services ?? AppointmentServices(),
      super(DoctorBookingInitial()) {
    on<LoadProviderAndOfferingsEvent>(_onLoadProviderAndOfferings);
    on<SelectVisitModeOfferingEvent>(_onSelectVisitModeOffering);
    on<SelectBookingDateEvent>(_onSelectBookingDate);
  }

  Future<void> _onLoadProviderAndOfferings(
    LoadProviderAndOfferingsEvent event,
    Emitter<DoctorBookingState> emit,
  ) async {
    emit(DoctorBookingLoadingState());

    try {
      final results = await Future.wait([
        appointmentServices.getProviderDetail(event.providerId),
        appointmentServices.getProviderOfferings(event.providerId),
      ]);

      final provider = results[0] as ProviderProfileModel;
      final offerings = results[1] as List<OfferingModel>;

      OfferingModel? initialOffering;
      if (offerings.isNotEmpty) {
        try {
          initialOffering = offerings.firstWhere(
            (o) => o.visitMode == VisitModeType.inPerson,
          );
        } catch (_) {
          initialOffering = offerings.first;
        }
      }

      if (initialOffering == null) {
        emit(
          DoctorBookingLoadedState(
            provider: provider,
            offerings: offerings,
            selectedOffering: null,
            selectedDate: event.initialDate,
            isSlotsLoading: false,
            slots: const [],
          ),
        );
        return;
      }

      emit(
        DoctorBookingLoadedState(
          provider: provider,
          offerings: offerings,
          selectedOffering: initialOffering,
          selectedDate: event.initialDate,
          isSlotsLoading: true,
          slots: const [],
        ),
      );

      await _fetchSlotsForCurrentSelection(
        emit: emit,
        provider: provider,
        offerings: offerings,
        selectedOffering: initialOffering,
        date: event.initialDate,
      );
    } catch (e) {
      emit(DoctorBookingFailedState(message: _errMsg(e)));
    }
  }

  Future<void> _onSelectVisitModeOffering(
    SelectVisitModeOfferingEvent event,
    Emitter<DoctorBookingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DoctorBookingLoadedState) return;

    emit(
      currentState.copyWith(
        selectedOffering: event.offering,
        selectedDate: event.date,
        isSlotsLoading: true,
        slots: const [],
        clearSlotsError: true,
      ),
    );

    await _fetchSlotsForCurrentSelection(
      emit: emit,
      provider: currentState.provider,
      offerings: currentState.offerings,
      selectedOffering: event.offering,
      date: event.date,
    );
  }

  Future<void> _onSelectBookingDate(
    SelectBookingDateEvent event,
    Emitter<DoctorBookingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DoctorBookingLoadedState) return;
    final offering = currentState.selectedOffering;
    if (offering == null) return;

    emit(
      currentState.copyWith(
        selectedDate: event.date,
        isSlotsLoading: true,
        slots: const [],
        clearSlotsError: true,
      ),
    );

    await _fetchSlotsForCurrentSelection(
      emit: emit,
      provider: currentState.provider,
      offerings: currentState.offerings,
      selectedOffering: offering,
      date: event.date,
    );
  }

  Future<void> _fetchSlotsForCurrentSelection({
    required Emitter<DoctorBookingState> emit,
    required ProviderProfileModel provider,
    required List<OfferingModel> offerings,
    required OfferingModel selectedOffering,
    required String date,
  }) async {
    try {
      final slotsResponse = await appointmentServices.getAvailableSlots(
        providerId: provider.id,
        offeringId: selectedOffering.id,
        date: date,
      );

      emit(
        DoctorBookingLoadedState(
          provider: provider,
          offerings: offerings,
          selectedOffering: selectedOffering,
          selectedDate: date,
          isSlotsLoading: false,
          slots: slotsResponse.results,
          slotsError: null,
        ),
      );
    } catch (e) {
      emit(
        DoctorBookingLoadedState(
          provider: provider,
          offerings: offerings,
          selectedOffering: selectedOffering,
          selectedDate: date,
          isSlotsLoading: false,
          slots: const [],
          slotsError: _errMsg(e),
        ),
      );
    }
  }

  String _errMsg(Object e) => getAppErrorMessage(e);
}
