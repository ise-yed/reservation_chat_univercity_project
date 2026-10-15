import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta/meta.dart';
import 'package:reservation_chat_univercity_project/features/profile/model/notification_model.dart';

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

    on<UploadFileEvent>(_onUploadFile);

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
