part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

/// -------------------- Register --------------------
class RegisterEvent extends AuthEvent {
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String password;
  final String passwordConfirm;

  RegisterEvent({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.password,
    required this.passwordConfirm,
  });
}

/// -------------------- Login --------------------
class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  LoginEvent({required this.email, required this.password});
}

/// -------------------- Logout --------------------
class LogoutEvent extends AuthEvent {}

/// -------------------- Forget Password Request --------------------
class ForgetPasswordRequestEvent extends AuthEvent {
  final String email;

  ForgetPasswordRequestEvent({required this.email});
}

/// -------------------- Forget Password Verify --------------------
class ForgetPasswordVerifyEvent extends AuthEvent {
  final String email;
  final String code;
  final String newPassword;
  final String newPasswordConfirm;

  ForgetPasswordVerifyEvent({
    required this.email,
    required this.code,
    required this.newPassword,
    required this.newPasswordConfirm,
  });
}

/// -------------------- Change Password Request --------------------
class ChangePasswordRequestEvent extends AuthEvent {}

/// -------------------- Change Password --------------------
class ChangePasswordEvent extends AuthEvent {
  final String currentPassword;
  final String code;
  final String newPassword;
  final String newPasswordConfirm;

  ChangePasswordEvent({
    required this.currentPassword,
    required this.code,
    required this.newPassword,
    required this.newPasswordConfirm,
  });
}
