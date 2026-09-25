part of 'auth_bloc.dart';

@immutable
abstract class AuthState {}

class AuthInitial extends AuthState {}

/// -------------------- Register --------------------
class RegisterLoading extends AuthState {}

class RegisterSuccess extends AuthState {
  final String message;

  RegisterSuccess(this.message);
}

class RegisterError extends AuthState {
  final String message;
  final Map<String, dynamic>? fieldErrors;

  RegisterError(this.message, {this.fieldErrors});
}

/// -------------------- Login --------------------
class LoginLoading extends AuthState {}

class LoginSuccess extends AuthState {
  final UserModel user;

  LoginSuccess(this.user);
}

class LoginError extends AuthState {
  final String message;
  final Map<String, dynamic>? fieldErrors;

  LoginError(this.message, {this.fieldErrors});
}

/// -------------------- Logout --------------------
class LogoutLoading extends AuthState {}

class LogoutSuccess extends AuthState {}

class LogoutError extends AuthState {
  final String message;

  LogoutError(this.message);
}


/// -------------------- Forget Password Request --------------------
class ForgetPasswordRequestLoading extends AuthState {}

class ForgetPasswordRequestSuccess extends AuthState {
  final String message;

  ForgetPasswordRequestSuccess(this.message);
}

class ForgetPasswordRequestError extends AuthState {
  final String message;
  final Map<String, dynamic>? fieldErrors;

  ForgetPasswordRequestError(this.message, {this.fieldErrors});
}

/// -------------------- Forget Password Verify --------------------
class ForgetPasswordVerifyLoading extends AuthState {}

class ForgetPasswordVerifySuccess extends AuthState {
  final String message;

  ForgetPasswordVerifySuccess(this.message);
}

class ForgetPasswordVerifyError extends AuthState {
  final String message;
  final Map<String, dynamic>? fieldErrors;

  ForgetPasswordVerifyError(this.message, {this.fieldErrors});
}


/// -------------------- Change Password Request --------------------
class ChangePasswordRequestLoading extends AuthState {}

class ChangePasswordRequestSuccess extends AuthState {
  final String message;

  ChangePasswordRequestSuccess(this.message);
}

class ChangePasswordRequestError extends AuthState {
  final String message;
  final Map<String, dynamic>? fieldErrors;

  ChangePasswordRequestError(this.message, {this.fieldErrors});
}


/// -------------------- Change Password --------------------
class ChangePasswordLoading extends AuthState {}

class ChangePasswordSuccess extends AuthState {
  final String message;

  ChangePasswordSuccess(this.message);
}

class ChangePasswordError extends AuthState {
  final String message;
  final Map<String, dynamic>? fieldErrors;

  ChangePasswordError(this.message, {this.fieldErrors});
}
