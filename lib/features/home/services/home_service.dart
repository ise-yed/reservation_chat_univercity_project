import 'package:dio/dio.dart';
import 'package:reservation_chat_univercity_project/core/utils/api_provider.dart';
import 'package:reservation_chat_univercity_project/core/utils/app_error.dart';
import 'package:reservation_chat_univercity_project/features/home/services/model/home_models.dart';

class HomeServices {
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await apiProvider.get('categories/');
      final data = response.data;

      if (data is Map<String, dynamic> && data['results'] is List) {
        return List<CategoryModel>.from(
          (data['results'] as List).map(
            (x) => CategoryModel.fromJson(Map<String, dynamic>.from(x)),
          ),
        );
      } else if (data is List) {
        return List<CategoryModel>.from(
          data.map((x) => CategoryModel.fromJson(Map<String, dynamic>.from(x))),
        );
      }
      return const [];
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  Future<PaginatedProvidersResponse> getProviders({
    required int page,
    int pageSize = 10,
    String? specialtyId,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (specialtyId != null && specialtyId.trim().isNotEmpty) {
        queryParams['specialty_id'] = specialtyId.trim();
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final response = await apiProvider.get(
        'providers/',
        queryParameters: queryParams,
      );

      return PaginatedProvidersResponse.fromJson(
        response.data,
        currentPage: page,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }
}
