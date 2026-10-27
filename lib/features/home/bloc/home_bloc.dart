import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:reservation_chat_univercity_project/core/utils/app_error.dart';
import 'package:reservation_chat_univercity_project/features/home/services/home_service.dart';
import 'package:reservation_chat_univercity_project/features/home/services/model/home_models.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeServices homeServices;

  HomeBloc([HomeServices? services])
    : homeServices = services ?? HomeServices(),
      super(HomeInitial()) {
    on<GetHomeDataEvent>(_onGetHomeData);
    on<GetSpecialtyDoctorsEvent>(_onGetSpecialtyDoctors);
  }

  Future<void> _onGetHomeData(
    GetHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeDataLoadingState());
    try {
      final results = await Future.wait([
        homeServices.getCategories(),
        homeServices.getProviders(page: 1, pageSize: event.pageSize),
      ]);

      final categories = results[0] as List<CategoryModel>;
      final providersResponse = results[1] as PaginatedProvidersResponse;

      emit(
        HomeDataSuccessState(
          categories: categories,
          providersResponse: providersResponse,
        ),
      );
    } catch (e) {
      emit(HomeDataFailedState(message: _errMsg(e)));
    }
  }

  Future<void> _onGetSpecialtyDoctors(
    GetSpecialtyDoctorsEvent event,
    Emitter<HomeState> emit,
  ) async {
    if (event.page == 1) {
      emit(SpecialtyDoctorsLoadingState());
    }

    try {
      final response = await homeServices.getProviders(
        page: event.page,
        pageSize: event.pageSize,
        specialtyId: event.specialtyId,
        search: event.search,
      );
      emit(SpecialtyDoctorsSuccessState(providersResponse: response));
    } catch (e) {
      emit(SpecialtyDoctorsFailedState(message: _errMsg(e)));
    }
  }

  String _errMsg(Object e) => getAppErrorMessage(e);
}
