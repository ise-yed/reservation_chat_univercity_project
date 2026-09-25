part of 'blog_bloc.dart';

@immutable
sealed class BlogState {}

final class BlogInitial extends BlogState {}

// ! home reminder
class BlogHomeLoadingState extends BlogState {}

class BlogHomeSuccessState extends BlogState {
  final BlogResponse blogs;
   List<String>? categoriesList;
  String? tag;
  BlogHomeSuccessState({
    required this.blogs,
     this.categoriesList,
    this.tag,
  });
}

class BlogHomeFailedState extends BlogState {
  final String message;
  // String? tag;

  BlogHomeFailedState({required this.message});
}
