import 'package:dio/dio.dart';
import 'package:reservation_chat_univercity_project/core/utils/api_provider.dart';
import 'package:reservation_chat_univercity_project/core/utils/app_error.dart';
import 'package:reservation_chat_univercity_project/features/appointments/service/model/appointment_models.dart';
import 'package:reservation_chat_univercity_project/features/home/services/model/home_models.dart';

class AppointmentServices {
  /// دریافت جزئیات پروفایل یک پزشک: GET /api/v1/providers/<provider_id>/
  Future<ProviderProfileModel> getProviderDetail(String providerId) async {
    try {
      final response = await apiProvider.get('providers/$providerId/');
      if (response.data is Map<String, dynamic>) {
        return ProviderProfileModel.fromJson(
          Map<String, dynamic>.from(response.data),
        );
      }
      throw AppException(AppErrorCode.unknown, serverMessage: 'پزشک یافت نشد');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  /// دریافت لیست پروفایل‌های پزشکی کاربر جاری (ویژه پزشکان): GET /api/v1/providers/my/
  Future<List<ProviderProfileModel>> getMyProviderProfiles() async {
    try {
      final response = await apiProvider.get('providers/my/');
      final parsed = PaginatedProvidersResponse.fromJson(
        response.data,
        currentPage: 1,
      );
      return parsed.results;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  /// دریافت لیست خدمات فعال پزشک: GET /api/v1/offerings/providers/<provider_id>/
  Future<List<OfferingModel>> getProviderOfferings(String providerId) async {
    try {
      final response = await apiProvider.get(
        'offerings/providers/$providerId/',
      );
      final data = response.data;
      List<dynamic> rawList = const [];
      if (data is Map<String, dynamic> && data['results'] is List) {
        rawList = data['results'] as List;
      } else if (data is List) {
        rawList = data;
      }
      return rawList
          .map((x) => OfferingModel.fromJson(Map<String, dynamic>.from(x)))
          .where((o) => o.isActive)
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  /// دریافت ساعت‌های آزاد پزشک در تاریخ مشخص:
  /// GET /api/v1/availability/slots/?provider_id=X&offering_id=Y&date=YYYY-MM-DD
  Future<AvailableSlotsResponse> getAvailableSlots({
    required String providerId,
    required String offeringId,
    required String date,
  }) async {
    try {
      final response = await apiProvider.get(
        'availability/slots/',
        queryParameters: {
          'provider_id': providerId,
          'offering_id': offeringId,
          'date': date,
        },
      );
      if (response.data is Map<String, dynamic>) {
        return AvailableSlotsResponse.fromJson(
          Map<String, dynamic>.from(response.data),
        );
      }
      throw AppException(
        AppErrorCode.unknown,
        serverMessage: 'خطا در دریافت ساعت‌های خالی',
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  /// ثبت نوبت جدید: POST /api/v1/appointments/
  Future<AppointmentModel> createAppointment({
    required String providerId,
    required String offeringId,
    required String startAt,
    required String paymentMethod,
    String notes = '',
  }) async {
    try {
      final response = await apiProvider.post(
        'appointments/',
        data: {
          'provider_id': providerId,
          'offering_id': offeringId,
          'start_at': startAt,
          'payment_method': paymentMethod,
          'notes': notes,
        },
      );
      if (response.data is Map<String, dynamic>) {
        return AppointmentModel.fromJson(
          Map<String, dynamic>.from(response.data),
        );
      }
      throw AppException(
        AppErrorCode.unknown,
        serverMessage: 'خطا در ثبت نوبت',
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  /// دریافت نوبت‌های بیمار جاری: GET /api/v1/appointments/my/
  Future<PaginatedAppointmentsResponse> getMyAppointments({
    int page = 1,
    int pageSize = 50,
    String? status,
  }) async {
    try {
      final response = await apiProvider.get(
        'appointments/my/',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      return PaginatedAppointmentsResponse.fromJson(
        response.data,
        currentPage: page,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  /// دریافت نوبت‌های یک پزشک: GET /api/v1/appointments/providers/<provider_id>/
  Future<PaginatedAppointmentsResponse> getProviderAppointments({
    required String providerId,
    int page = 1,
    int pageSize = 50,
    String? status,
  }) async {
    try {
      final response = await apiProvider.get(
        'appointments/providers/$providerId/',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      return PaginatedAppointmentsResponse.fromJson(
        response.data,
        currentPage: page,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  /// لغو نوبت: POST /api/v1/appointments/<pk>/cancel/
  Future<AppointmentModel> cancelAppointment({
    required String appointmentId,
    String cancelReason = '',
  }) async {
    try {
      final response = await apiProvider.post(
        'appointments/$appointmentId/cancel/',
        data: {'cancel_reason': cancelReason},
      );
      return AppointmentModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  /// تغییر وضعیت نوبت توسط پزشک: PATCH /api/v1/appointments/<pk>/status/
  Future<AppointmentModel> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    try {
      final response = await apiProvider.patch(
        'appointments/$appointmentId/status/',
        data: {'status': status},
      );
      return AppointmentModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  /// خاتمه و تکمیل دستی ویزیت آنلاین توسط پزشک:
  /// POST /api/v1/appointments/<appointment_id>/complete/
  Future<void> completeOnlineVisit({required String appointmentId}) async {
    try {
      await apiProvider.post('appointments/$appointmentId/complete/');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  /// شروع یا تلاش مجدد پرداخت آنلاین: POST /api/v1/payments/<pk>/pay/
  Future<PaymentModel> startOnlinePayment({required String paymentId}) async {
    try {
      final response = await apiProvider.post('payments/$paymentId/pay/');
      return PaymentModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  /// فراخوانی مستقیم لینک بازگشت درگاه آزمایشی (MockGateway):
  /// GET <pay_url> (یا تغییر status=OK به status=NOK برای شبیه‌سازی خطا)
  Future<Map<String, dynamic>> verifyGatewayCallbackUrl({
    required String payUrl,
    bool simulateFailure = false,
  }) async {
    try {
      final targetUrl = simulateFailure
          ? payUrl.replaceAll('status=OK', 'status=NOK')
          : payUrl;
      final response = await apiProvider.getUri(Uri.parse(targetUrl));
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
      return {'status': 'paid'};
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  /// تایید پرداخت حضوری در مطب توسط پزشک: POST /api/v1/payments/<pk>/mark-paid/
  Future<PaymentModel> markPaidInPerson({required String paymentId}) async {
    try {
      final response = await apiProvider.post('payments/$paymentId/mark-paid/');
      return PaymentModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }
}
