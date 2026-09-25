import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta/meta.dart';
import 'package:reservation_chat_univercity_project/features/profile/model/notification_model.dart';
import 'package:reservation_chat_univercity_project/features/profile/model/pet_model.dart';
import 'package:reservation_chat_univercity_project/features/profile/model/ticket_data_model.dart';
import 'package:reservation_chat_univercity_project/features/profile/model/ticket_list_model.dart';

import '../../../core/utils/app_error.dart';
import '../../auth/models/user_model.dart';
import '../model/app_const_setting_model.dart';
import '../service/profile_service.dart';

part 'profile_event.dart';

part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileService profileServices;

  ProfileBloc(this.profileServices) : super(ProfileInitial()) {
    on<GetCurrentUserEvent>(_onGetCurrentUser);
    on<EditProfileEvent>(_onEditProfile);
    on<GetPetsEvent>(_onGetPets);
    on<GetBreedsEvent>(_onGetBreeds);
    on<UploadFileEvent>(_onUploadFile);
    // on<GetAppConstSettingEvent>(_onGetAppConstSetting);
    on<GetTicketListEvent>(_onGetTicketList);
    on<CreateTicketEvent>(_onCreateTicket);
    on<CloseTicketEvent>(_onCloseTicket);
    on<GetTicketSingleDataEvent>(_onGetSingleTicketData);
    on<ReplayTicketDataEvent>(_onReplayTicket);
    on<NotificationDataEvent>(_onNotificationData);
    // on<SeenNotificationEvent>(_onSeenNotification);
  }

  /// -------------------- Get Current User --------------------
  Future<void> _onGetCurrentUser(
    GetCurrentUserEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(GetCurrentUserLoading());
    try {
      final user = await profileServices.getCurrentUser();
      emit(GetCurrentUserSuccess(user));
    } catch (e) {
      emit(GetCurrentUserError(_errMsg(e)));
    }
  }

  /// -------------------- Edit Profile --------------------
  Future<void> _onEditProfile(
    EditProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(EditProfileLoading());
    try {
      final user = await profileServices.editProfile(user: event.user);
      emit(EditProfileSuccess(user));
    } catch (e) {
      emit(EditProfileError(_errMsg(e)));
    }
  }

  /// -------------------- Get Pets --------------------
  Future<void> _onGetPets(
    GetPetsEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(GetPetsLoading());
    try {
      final user = await profileServices.getPets();
      emit(GetPetsSuccess(user));
    } catch (e) {
      emit(GetPetsError(_errMsg(e)));
    }
  }

  /// -------------------- Get Breeds --------------------
  Future<void> _onGetBreeds(
    GetBreedsEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(GetBreedsLoading());
    try {
      final user = await profileServices.getBreeds(event.pet);
      emit(GetBreedsSuccess(user));
    } catch (e) {
      emit(GetBreedsError(_errMsg(e)));
    }
  }

  /// -------------------- Upload File --------------------
  Future<void> _onUploadFile(
    UploadFileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final fileName = await profileServices.uploadFile(
        event.file,
        onProgress: (sent, total) {
          final p = total > 0 ? (sent / total).clamp(0.0, 1.0) : 0.0;
          emit(UploadFileLoading(event.tempId, p));
        },
      );

      emit(UploadFileSuccess(tempId: event.tempId, fileName: fileName));
    } catch (e) {
      emit(UploadFileError(tempId: event.tempId, message: _errMsg(e)));
    }
  }

  /// -------------------- Get Breeds --------------------
  // Future<void> _onGetAppConstSetting(
  //   GetAppConstSettingEvent event,
  //   Emitter<ProfileState> emit,
  // ) async {
  //   emit(AppConstSettingLoading());
  //   try {
  //     final user = await profileServices.getAppConstSetting();
  //     emit(AppConstSettingSuccess(user));
  //   } catch (e) {
  //     emit(AppConstSettingError(_errMsg(e)));
  //   }
  // }

  Future<void> _onGetTicketList(
    GetTicketListEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(GetTicketListLoadingState());
    try {
      final tickets = await profileServices.getTickets();
      emit(GetTicketListSuccessState(tickets));
    } catch (e) {
      emit(GetTicketListErrorState(_errMsg(e)));
    }
  }

  Future<void> _onCreateTicket(
    CreateTicketEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(CreateTicketLoadingState());
    try {
      final ticket = await profileServices.createTicket(
        subject: event.subject,
        description: event.description,
        message: event.message,
      );
      emit(CreateTicketSuccessState(ticket));
    } catch (e) {
      emit(CreateTicketErrorState(_errMsg(e)));
    }
  }

  Future<void> _onCloseTicket(
    CloseTicketEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(CloseTicketLoadingState());
    try {
      final ticket = await profileServices.closeTicket(id: event.id);
      emit(CloseTicketSuccessState(ticket));
    } catch (e) {
      emit(CloseTicketErrorState(_errMsg(e)));
    }
  }

  Future<void> _onGetSingleTicketData(
    GetTicketSingleDataEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(TicketSingleDataLoadingState());
    try {
      final ticket = await profileServices.getMessageTicket(id: event.id);
      emit(TicketSingleDataSuccessState(ticket));
    } catch (e) {
      emit(TicketSingleDataErrorState(_errMsg(e)));
    }
  }

  Future<void> _onReplayTicket(
    ReplayTicketDataEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ReplayTicketLoadingState());
    try {
      final ticket = await profileServices.replayTicket(
        id: event.id,
        document: event.document,
        message: event.message,
      );
      emit(ReplayTicketSuccessState(ticket));
    } catch (e) {
      emit(ReplayTicketErrorState(_errMsg(e), event.message, event.document));
    }
  }

  Future<void> _onNotificationData(
    NotificationDataEvent event,
    Emitter<ProfileState> emit,
  ) async {
    if (event.page == 1) {
      emit(NotificationDataLoadingState());
    }

    try {
      final dataList = await profileServices.getNotificationData(
        limit: event.limit,
        page: event.page,
      );
      if (event.callSeen) {
        var data = await profileServices.seenNotification();
      }
      emit(NotificationDataSuccessState(dataList));
    } catch (e) {
      emit(NotificationDataFailedState(_errMsg(e)));
    }
  }

  // Future<void> _onSeenNotification(
  //   SeenNotificationEvent event,
  //   Emitter<ProfileState> emit,
  // ) async {
  //   emit(SeenNotificationLoadingState());
  //   try {
  //     await profileServices.seenNotification();

  //     emit(SeenNotificationSuccessState());
  //   } catch (e) {
  //     emit(SeecNotificationFailedState(_errMsg(e)));
  //   }
  // }

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
