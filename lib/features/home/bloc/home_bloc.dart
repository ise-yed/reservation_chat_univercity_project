import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:reservation_chat_univercity_project/core/utils/app_error.dart';

// import 'package:reservation_chat_univercity_project/features/home/services/home_services.dart';

// import 'package:reservation_chat_univercity_project/features/messaging/service/chat_service.dart';
// import 'package:reservation_chat_univercity_project/features/messaging/service/model/chat_room_model.dart';

part 'home_event.dart';

part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    on<GetPartnersEvent>(_onGetPartners);
  }

  Future<void> _onGetPartners(
    GetPartnersEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(GetPartnersLoadingState());

    try {
      // final groupAdsData = await homeServices.getPartners();

      // emit(GetPartnersSuccessState(groupAdsData: groupAdsData));
    } catch (e) {
      emit(GetPartnersFailedState(message: _errMsg(e)));
    }
  }

  String _errMsg(Object e) => getAppErrorMessage(e);
}
