part of 'home_bloc.dart';

@immutable
sealed class HomeEvent {}

class GetHomeDataEvent extends HomeEvent {
  final int pageSize;

  GetHomeDataEvent({this.pageSize = 10});
}

class GetSpecialtyDoctorsEvent extends HomeEvent {
  final int page;
  final int pageSize;
  final String? specialtyId;
  final String? search;

  GetSpecialtyDoctorsEvent({
    required this.page,
    this.pageSize = 10,
    this.specialtyId,
    this.search,
  });
}
