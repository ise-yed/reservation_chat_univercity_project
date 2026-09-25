import 'package:dio/dio.dart';
import '../../../core/utils/api_provider.dart';
import '../../../core/utils/app_error.dart';
import '../model/onboarding_model.dart';

class OnboardingService {
  Future<List<OnboardingModel>> getOnboardings() async {
    try {
      final response = await apiProvider.get('setting/intro/');
      final data = response.data;
      if (data is List) {
        return data
            .map(
              (e) =>
                  OnboardingModel.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      }
      if (data is Map<String, dynamic> && data['results'] is List) {
        return (data['results'] as List)
            .map(
              (e) =>
                  OnboardingModel.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      }
      throw AppException(
        AppErrorCode.unknown,
        serverMessage: 'ساختار پاسخ غیرمنتظره است. انتظار لیست داشتیم.',
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    } catch (e) {
      throw AppException(AppErrorCode.unknown, serverMessage: e.toString());
    }
  }
}
