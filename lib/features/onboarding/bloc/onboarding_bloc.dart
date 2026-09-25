import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:meta/meta.dart';
import 'package:reservation_chat_univercity_project/features/onboarding/model/onboarding_model.dart';
import 'package:reservation_chat_univercity_project/features/onboarding/services/onboarding_service.dart';

import '../../../core/utils/app_error.dart';

part 'onboarding_event.dart';

part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingService onboardingService;

  OnboardingBloc(this.onboardingService) : super(OnboardingInitial()) {
    on<GetOnboardingEvent>(_onGetOnboarding);
  }

  Future<void> _onGetOnboarding(
    GetOnboardingEvent event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(GetOnboardingLoading());
    try {
      final user = await onboardingService.getOnboardings();
      emit(GetOnboardingSuccess(user));
    } catch (e) {
      emit(GetOnboardingError(_errMsg(e)));
    }
  }

  String _errMsg(Object e) {
    if (e is AppException) {
      // if (e.serverMessage != null && e.serverMessage!.trim().isNotEmpty) {
      //   return e.serverMessage!.trim();
      // }
      return e.i18nKey.tr();
    }
    return e.toString();
  }
}
