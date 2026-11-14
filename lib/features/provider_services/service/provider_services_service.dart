import 'package:dio/dio.dart';
import 'package:reservation_chat_univercity_project/core/utils/api_provider.dart';
import 'package:reservation_chat_univercity_project/core/utils/app_error.dart';
import 'package:reservation_chat_univercity_project/features/appointments/service/appointment_service.dart';
import 'package:reservation_chat_univercity_project/features/home/services/home_service.dart';
import 'package:reservation_chat_univercity_project/features/home/services/model/home_models.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/service/model/provider_services_models.dart';

/// Service layer for managing a provider's offerings, working hours, time-offs,
/// and basic scheduling profile settings.
class ProviderServicesService {
  final Dio _dio;
  final AppointmentServices _appointmentServices;
  final HomeServices _homeServices;

  ProviderServicesService({
    Dio? dio,
    AppointmentServices? appointmentServices,
    HomeServices? homeServices,
  }) : _dio = dio ?? apiProvider,
       _appointmentServices = appointmentServices ?? AppointmentServices(),
       _homeServices = homeServices ?? HomeServices();

  Future<T> _request<T>(
    Future<Response<dynamic>> Function() call,
    T Function(dynamic data) parser,
  ) async {
    try {
      final response = await call();
      return parser(response.data);
    } on DioException catch (e) {
      if (e.error is AppException) {
        throw e.error as AppException;
      }
      rethrow;
    }
  }

  Future<List<ProviderProfileModel>> getMyProviderProfiles() {
    return _appointmentServices.getMyProviderProfiles();
  }

  Future<List<CategoryModel>> getCategories() {
    return _homeServices.getCategories();
  }

  Future<List<MyOrganizationModel>> getMyOrganizations() {
    return _request(
      () => _dio.get(
        'organizations/my/',
        queryParameters: {'page_size': 100},
      ),
      (data) => parsePaginatedOrList(data, MyOrganizationModel.fromJson),
    );
  }

  Future<List<ProviderOfferingModel>> getProviderOfferings(String providerId) {
    return _request(
      () => _dio.get(
        'offerings/providers/$providerId/',
        queryParameters: {'page_size': 100},
      ),
      (data) => parsePaginatedOrList(data, ProviderOfferingModel.fromJson),
    );
  }

  Future<ProviderOfferingModel> createOffering({
    required String organizationId,
    required String providerId,
    required OfferingFormPayload payload,
  }) {
    return _request(
      () => _dio.post(
        'offerings/',
        data: payload.toCreateJson(
          organizationId: organizationId,
          providerId: providerId,
        ),
      ),
      (data) =>
          ProviderOfferingModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<ProviderOfferingModel> updateOffering({
    required String offeringId,
    required Map<String, dynamic> data,
  }) {
    return _request(
      () => _dio.patch('offerings/$offeringId/', data: data),
      (resData) => ProviderOfferingModel.fromJson(
        Map<String, dynamic>.from(resData as Map),
      ),
    );
  }

  Future<List<WorkingHourModel>> getProviderWorkingHours(String providerId) {
    return _request(
      () => _dio.get(
        'availability/providers/$providerId/working-hours/',
        queryParameters: {'page_size': 100},
      ),
      (data) {
        final list = parsePaginatedOrList(data, WorkingHourModel.fromJson);
        list.sort(WorkingHourModel.compareForSchedule);
        return list;
      },
    );
  }

  Future<WorkingHourModel> createWorkingHour({
    required String providerId,
    required int weekday,
    required String startTime,
    required String endTime,
    bool isActive = true,
  }) {
    return _request(
      () => _dio.post(
        'availability/working-hours/',
        data: {
          'provider_id': providerId,
          'weekday': weekday,
          'start_time': startTime,
          'end_time': endTime,
          'is_active': isActive,
        },
      ),
      (data) => WorkingHourModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<WorkingHourModel> updateWorkingHour({
    required String workingHourId,
    required Map<String, dynamic> data,
  }) {
    return _request(
      () => _dio.patch(
        'availability/working-hours/$workingHourId/',
        data: data,
      ),
      (resData) =>
          WorkingHourModel.fromJson(Map<String, dynamic>.from(resData as Map)),
    );
  }

  Future<List<TimeOffModel>> getProviderTimeOffs(String providerId) {
    return _request(
      () => _dio.get(
        'availability/providers/$providerId/time-offs/',
        queryParameters: {'page_size': 100},
      ),
      (data) => parsePaginatedOrList(data, TimeOffModel.fromJson),
    );
  }

  Future<TimeOffModel> createTimeOff({
    required String providerId,
    required DateTime startAt,
    required DateTime endAt,
    String reason = '',
    bool isActive = true,
  }) {
    return _request(
      () => _dio.post(
        'availability/time-offs/',
        data: {
          'provider_id': providerId,
          'start_at': startAt.toUtc().toIso8601String(),
          'end_at': endAt.toUtc().toIso8601String(),
          'reason': reason.trim(),
          'is_active': isActive,
        },
      ),
      (data) => TimeOffModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<TimeOffModel> updateTimeOff({
    required String timeOffId,
    required Map<String, dynamic> data,
  }) {
    return _request(
      () => _dio.patch(
        'availability/time-offs/$timeOffId/',
        data: data,
      ),
      (resData) =>
          TimeOffModel.fromJson(Map<String, dynamic>.from(resData as Map)),
    );
  }

  Future<ProviderProfileModel> updateProviderProfile({
    required String providerId,
    String? title,
    String? bio,
    int? defaultSlotDurationMinutes,
    List<String>? specialtyIds,
  }) {
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title.trim();
    if (bio != null) payload['bio'] = bio.trim();
    if (defaultSlotDurationMinutes != null) {
      payload['default_slot_duration_minutes'] = defaultSlotDurationMinutes;
    }
    if (specialtyIds != null) payload['specialty_ids'] = specialtyIds;

    return _request(
      () => _dio.patch('providers/$providerId/', data: payload),
      (resData) => ProviderProfileModel.fromJson(
        Map<String, dynamic>.from(resData as Map),
      ),
    );
  }
}

