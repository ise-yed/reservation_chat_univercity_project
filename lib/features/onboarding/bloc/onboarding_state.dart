part of 'onboarding_bloc.dart';

@immutable
sealed class OnboardingState {}

final class OnboardingInitial extends OnboardingState {}

class GetOnboardingLoading extends OnboardingState {}

class GetOnboardingSuccess extends OnboardingState {
  final List<OnboardingModel> onboarding;

  GetOnboardingSuccess(this.onboarding);
}

class GetOnboardingError extends OnboardingState {
  final String message;

  GetOnboardingError(this.message);
}
