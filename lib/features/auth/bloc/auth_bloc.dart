import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../core/utils/app_error.dart';
import '../models/user_model.dart';
import '../service/auth_service.dart';

part 'auth_event.dart';

part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthServices authServices;

  AuthBloc(this.authServices) : super(AuthInitial()) {
    on<RegisterEvent>(_onRegister);
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<ForgetPasswordRequestEvent>(_onForgetPasswordRequest);
    on<ForgetPasswordVerifyEvent>(_onForgetPasswordVerify);
    on<ChangePasswordRequestEvent>(_onChangePasswordRequest);
    on<ChangePasswordEvent>(_onChangePassword);
  }

  /// -------------------- Register --------------------
  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(RegisterLoading());
    try {
      final message = await authServices.register(
        email: event.email,
        firstName: event.firstName,
        lastName: event.lastName,
        phoneNumber: event.phoneNumber,
        password: event.password,
        passwordConfirm: event.passwordConfirm,
      );
      emit(RegisterSuccess(message));
    } catch (e) {
      Map<String, dynamic>? errors;
      if (e is AppException) {
        errors = e.errors;
      }
      emit(RegisterError(_errMsg(e, includeFieldErrors: false), fieldErrors: errors));
    }
  }

  /// -------------------- Login --------------------
  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(LoginLoading());
    try {
      final user = await authServices.login(
        email: event.email,
        password: event.password,
      );
      emit(LoginSuccess(user));
    } catch (e) {
      Map<String, dynamic>? errors;
      if (e is AppException) {
        errors = e.errors;
      }
      emit(LoginError(_errMsg(e, includeFieldErrors: false), fieldErrors: errors));
    }
  }

  /// -------------------- Logout --------------------
  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(LogoutLoading());
    try {
      await authServices.logout();
      emit(LogoutSuccess());
    } catch (e) {
      emit(LogoutError(_errMsg(e)));
    }
  }

  /// -------------------- Forget Password Request --------------------
  Future<void> _onForgetPasswordRequest(
    ForgetPasswordRequestEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(ForgetPasswordRequestLoading());
    try {
      final message = await authServices.forgetPasswordRequest(
        email: event.email,
      );
      emit(ForgetPasswordRequestSuccess(message));
    } catch (e) {
      Map<String, dynamic>? errors;
      if (e is AppException) {
        errors = e.errors;
      }
      emit(ForgetPasswordRequestError(_errMsg(e, includeFieldErrors: false), fieldErrors: errors));
    }
  }

  /// -------------------- Forget Password Verify --------------------
  Future<void> _onForgetPasswordVerify(
    ForgetPasswordVerifyEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(ForgetPasswordVerifyLoading());
    try {
      final message = await authServices.forgetPasswordVerify(
        email: event.email,
        code: event.code,
        newPassword: event.newPassword,
        newPasswordConfirm: event.newPasswordConfirm,
      );
      emit(ForgetPasswordVerifySuccess(message));
    } catch (e) {
      Map<String, dynamic>? errors;
      if (e is AppException) {
        errors = e.errors;
      }
      emit(ForgetPasswordVerifyError(_errMsg(e, includeFieldErrors: false), fieldErrors: errors));
    }
  }
  
  /// -------------------- Change Password Request --------------------
  Future<void> _onChangePasswordRequest(
    ChangePasswordRequestEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(ChangePasswordRequestLoading());
    try {
      final message = await authServices.changePasswordRequest();
      emit(ChangePasswordRequestSuccess(message));
    } catch (e) {
      Map<String, dynamic>? errors;
      if (e is AppException) {
        errors = e.errors;
      }
      emit(ChangePasswordRequestError(_errMsg(e, includeFieldErrors: false), fieldErrors: errors));
    }
  }

  /// -------------------- Change Password --------------------
  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(ChangePasswordLoading());
    try {
      final message = await authServices.changePassword(
        currentPassword: event.currentPassword,
        code: event.code,
        newPassword: event.newPassword,
        newPasswordConfirm: event.newPasswordConfirm,
      );
      emit(ChangePasswordSuccess(message));
    } catch (e) {
      Map<String, dynamic>? errors;
      if (e is AppException) {
        errors = e.errors;
      }
      emit(ChangePasswordError(_errMsg(e, includeFieldErrors: false), fieldErrors: errors));
    }
  }

  String _errMsg(Object e, {bool includeFieldErrors = true}) {
    return getAppErrorMessage(e, includeFieldErrors: includeFieldErrors);
  }
}

