import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:reservation_chat_univercity_project/core/utils/app_error.dart';
import 'package:reservation_chat_univercity_project/features/blog/service/blog_service.dart';
import 'package:reservation_chat_univercity_project/features/blog/service/model/blog_model.dart';

part 'blog_event.dart';
part 'blog_state.dart';

class BlogBloc extends Bloc<BlogEvent, BlogState> {
  final BlogServices blogServices;

  BlogBloc(this.blogServices) : super(BlogInitial()) {
    on<GetBlogHomeListEvent>(_onBlogHomeData);
    // on<GetBlogHomeCategoriesListEvent>(_onHomeCategoriesData);
  }

  Future<void> _onBlogHomeData(
    GetBlogHomeListEvent event,
    Emitter<BlogState> emit,
  ) async {
    if (event.page == 1) {
      emit(BlogHomeLoadingState());
    }

    try {
      final dataList = await blogServices.getBlogHomeData(
        limit: event.limit,
        page: event.page,
        selectedTags: event.tags,
        q: event.q,
      );
      if (event.getCategories) {
        List<String> categoriesList = ["همه"];

        final categoriesListData = await blogServices.getCategoriesList();
        categoriesList.addAll(categoriesListData);

        emit(
          BlogHomeSuccessState(
            blogs: dataList,
            categoriesList: categoriesList,
            tag: event.tags,
          ),
        );
        return;
      }
      emit(BlogHomeSuccessState(blogs: dataList, tag: event.tags));
    } catch (e) {
      emit(BlogHomeFailedState(message: _errMsg(e)));
    }
  }

  String _errMsg(Object e) => getAppErrorMessage(e);
}
