part of 'profile_bloc.dart';

@immutable
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

/// -------------------- Get Current User --------------------
class GetCurrentUserLoading extends ProfileState {}

class GetCurrentUserSuccess extends ProfileState {
  final UserModel user;

  GetCurrentUserSuccess(this.user);
}

class GetCurrentUserError extends ProfileState {
  final String message;

  GetCurrentUserError(this.message);
}

/// -------------------- Edit Profile --------------------
class EditProfileLoading extends ProfileState {}

class EditProfileSuccess extends ProfileState {
  final UserModel user;

  EditProfileSuccess(this.user);
}

class EditProfileError extends ProfileState {
  final String message;

  EditProfileError(this.message);
}

/// -------------------- Get Pets --------------------
class GetPetsLoading extends ProfileState {}

class GetPetsSuccess extends ProfileState {
  final List<PetModel> pets;

  GetPetsSuccess(this.pets);
}

class GetPetsError extends ProfileState {
  final String message;

  GetPetsError(this.message);
}

/// -------------------- Get Breeds --------------------
class GetBreedsLoading extends ProfileState {}

class GetBreedsSuccess extends ProfileState {
  final List<PetModel> pets;

  GetBreedsSuccess(this.pets);
}

class GetBreedsError extends ProfileState {
  final String message;

  GetBreedsError(this.message);
}

/// -------------------- Upload File --------------------

class UploadFileLoading extends ProfileState {
  final int tempId;
  final double progress;
  UploadFileLoading(this.tempId, this.progress);
}

class UploadFileSuccess extends ProfileState {
  final int tempId;
  final String fileName;
  UploadFileSuccess({required this.tempId, required this.fileName});
}

class UploadFileError extends ProfileState {
  final int tempId;
  final String message;

  UploadFileError({required this.tempId, required this.message});
}

/// -------------------- App Const Setting --------------------
class AppConstSettingLoading extends ProfileState {}

class AppConstSettingSuccess extends ProfileState {
  final AppConstSettingModel appConstSetting;

  AppConstSettingSuccess(this.appConstSetting);
}

class AppConstSettingError extends ProfileState {
  final String message;

  AppConstSettingError(this.message);
}

/// -------------------- ticket --------------------
//! get main ticket list
class GetTicketListLoadingState extends ProfileState {}

class GetTicketListSuccessState extends ProfileState {
  final List<TicketListModel>? tickets;

  GetTicketListSuccessState(this.tickets);
}

class GetTicketListErrorState extends ProfileState {
  final String message;

  GetTicketListErrorState(this.message);
}

//! create ticket
class CreateTicketLoadingState extends ProfileState {}

class CreateTicketSuccessState extends ProfileState {
  final TicketListModel? ticket;

  CreateTicketSuccessState(this.ticket);
}

class CreateTicketErrorState extends ProfileState {
  final String message;

  CreateTicketErrorState(this.message);
}

// ! close ticket
class CloseTicketLoadingState extends ProfileState {}

class CloseTicketSuccessState extends ProfileState {
  final TicketListModel? ticket;

  CloseTicketSuccessState(this.ticket);
}

class CloseTicketErrorState extends ProfileState {
  final String message;

  CloseTicketErrorState(this.message);
}

// ! get ticket data
class TicketSingleDataLoadingState extends ProfileState {}

class TicketSingleDataSuccessState extends ProfileState {
  final SingleTicketModel? ticket;

  TicketSingleDataSuccessState(this.ticket);
}

class TicketSingleDataErrorState extends ProfileState {
  final String message;

  TicketSingleDataErrorState(this.message);
}

// ! replay ticket
class ReplayTicketLoadingState extends ProfileState {}

class ReplayTicketSuccessState extends ProfileState {
  final TicketMessageData? ticket;

  ReplayTicketSuccessState(this.ticket);
}

class ReplayTicketErrorState extends ProfileState {
  final String message;
  String? inputText;
  String? file;

  ReplayTicketErrorState(this.message, this.inputText, this.file);
}

// ! notification
class NotificationDataLoadingState extends ProfileState {}

class NotificationDataSuccessState extends ProfileState {
  final NotificationModel? notificationModel;

  NotificationDataSuccessState(this.notificationModel);
}

class NotificationDataFailedState extends ProfileState {
  final String message;

  NotificationDataFailedState(this.message);
}

class SeenNotificationLoadingState extends ProfileState {}

class SeenNotificationSuccessState extends ProfileState {
  SeenNotificationSuccessState();
}

class SeecNotificationFailedState extends ProfileState {
  final String message;

  SeecNotificationFailedState(this.message);
}
