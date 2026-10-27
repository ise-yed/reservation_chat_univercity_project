part of 'home_bloc.dart';

@immutable
sealed class HomeState {}

final class HomeInitial extends HomeState {}

class HomeDataLoadingState extends HomeState {}

class HomeDataSuccessState extends HomeState {
  final List<CategoryModel> categories;
  final PaginatedProvidersResponse providersResponse;

  HomeDataSuccessState({
    required this.categories,
    required this.providersResponse,
  });
}

class HomeDataFailedState extends HomeState {
  final String message;

  HomeDataFailedState({required this.message});
}

class SpecialtyDoctorsLoadingState extends HomeState {}

class SpecialtyDoctorsSuccessState extends HomeState {
  final PaginatedProvidersResponse providersResponse;

  SpecialtyDoctorsSuccessState({required this.providersResponse});
}

class SpecialtyDoctorsFailedState extends HomeState {
  final String message;

  SpecialtyDoctorsFailedState({required this.message});
}
