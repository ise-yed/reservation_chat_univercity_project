import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:reservation_chat_univercity_project/features/blog/service/model/blog_model.dart';

import '../../../core/utils/api_provider.dart';
import '../../../core/utils/app_error.dart';

class BlogServices {
  Future<BlogResponse> getBlogHomeData({
    required int page,
    required int limit,
    String? selectedTags,
    String? q,
  }) async {
    try {
      final response = await apiProvider.get(
        'blog/',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (selectedTags != null) 'tags': jsonEncode([selectedTags]),
          if (q != null) 'q': q,
        },
      );
      final blogsList = response.data;
      if (blogsList is Map<String, dynamic>) {
        return BlogResponse.fromJson(blogsList);
      }
      throw AppException(
        AppErrorCode.unknown,
        serverMessage: 'No reminder List',
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }

  Future<List<String>> getCategoriesList() async {
    try {
      final response = await apiProvider.get('blog/tags');
      return List<String>.from(response.data);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error as AppException;
      throw AppException(AppErrorCode.unknown, serverMessage: e.message);
    }
  }
}
