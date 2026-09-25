part of 'blog_bloc.dart';

@immutable
sealed class BlogEvent {}

class GetBlogHomeListEvent extends BlogEvent {
  final int page;
  final int limit;
  String? tags;
  bool getCategories;
  String? q;

  GetBlogHomeListEvent({
    required this.page,
    required this.limit,
    this.tags,
    this.getCategories = false,
    this.q,
  });
}

class GetBlogHomeCategoriesListEvent extends BlogEvent {
  GetBlogHomeCategoriesListEvent();
}
