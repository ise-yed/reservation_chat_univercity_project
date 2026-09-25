import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_constants.dart';
import 'package:reservation_chat_univercity_project/core/utils/navigator.dart';
import 'package:reservation_chat_univercity_project/core/utils/search_box_widget.dart';
import 'package:reservation_chat_univercity_project/core/widgets/app_cached_image.dart';
import 'package:reservation_chat_univercity_project/core/widgets/format_reminder_date.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_error_section.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_loading_section.dart';
import 'package:reservation_chat_univercity_project/core/widgets/pagination_error.dart';
import 'package:reservation_chat_univercity_project/core/widgets/pagination_indicator.dart';
import 'package:reservation_chat_univercity_project/features/blog/bloc/blog_bloc.dart';
import 'package:reservation_chat_univercity_project/features/blog/service/model/blog_model.dart';
import 'package:reservation_chat_univercity_project/features/blog/single_blog_screen.dart';

import '../../core/widgets/categories_list_filter.dart';

class HomeBlogsScreen extends StatefulWidget {
  const HomeBlogsScreen({super.key});

  @override
  State<HomeBlogsScreen> createState() => _HomeBlogsScreenState();
}

class _HomeBlogsScreenState extends State<HomeBlogsScreen> {
  final PagingController<int, Blog> _pagingController = PagingController(
    firstPageKey: 1,
  );
  String? _selectedTags;
  final TextEditingController _serachBoxController = TextEditingController();

  int listLimit = 10;

  @override
  void initState() {
    super.initState();
    final bloc = BlocProvider.of<BlogBloc>(context);
    _pagingController.addPageRequestListener((pageKey) {
      bloc.add(
        GetBlogHomeListEvent(
          page: pageKey,
          limit: listLimit,
          tags: _selectedTags,
          getCategories: pageKey == 1 ? true : false,
          q: _serachBoxController.text.trim(),
        ),
      );
    });
  }

  List<String>? _categoriesList;

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<BlogBloc>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: BlocConsumer<BlogBloc, BlogState>(
          buildWhen: (previous, current) =>
              current is BlogHomeLoadingState ||
              current is BlogHomeSuccessState ||
              current is BlogHomeFailedState,
          listener: (context, state) {
            if (state is BlogHomeSuccessState) {
              _selectedTags = state.tag;
              final dataModel = state.blogs;
              final newItems = dataModel.blogsList!;
              if (state.categoriesList != null) {
                _categoriesList = state.categoriesList!;
              }

              final nextPageKey = dataModel.nextPage;
              if (dataModel.hasPrevPage == false && dataModel.page == 1) {
                _pagingController.value = PagingState(
                  nextPageKey: dataModel.nextPage,
                  error: null,
                  itemList: [],
                );
              }
              if (nextPageKey == null) {
                _pagingController.appendLastPage(newItems);
              } else {
                _pagingController.appendPage(newItems, nextPageKey);
              }
            } else if (state is BlogHomeFailedState) {
              _pagingController.error = state.message;
            }
          },
          builder: (context, state) {
            final isFirstPage =
                _pagingController.itemList == null ||
                _pagingController.itemList!.isEmpty;
            return Column(
              children: [
                SearchBoxWidget(
                  onChanged: (value) {
                    _pagingController.value = PagingState(
                      nextPageKey: null,
                      error: null,
                      itemList: [],
                    );
                    bloc.add(
                      GetBlogHomeListEvent(
                        page: 1,
                        limit: listLimit,
                        tags: _selectedTags,
                        getCategories: false,
                        q: value,
                      ),
                    );
                  },
                  onCloseTap: () {
                    _serachBoxController.clear();
                    _pagingController.value = PagingState(
                      nextPageKey: null,
                      error: null,
                      itemList: [],
                    );
                    bloc.add(
                      GetBlogHomeListEvent(
                        page: 1,
                        limit: listLimit,
                        tags: _selectedTags,
                        getCategories: _categoriesList != null ? false : true,
                      ),
                    );
                  },

                  controller: _serachBoxController,
                  haveFilter: false,
                  backColor: Theme.of(context).colorScheme.shadow,
                  margin: EdgeInsets.only(
                    left: 24.w,
                    right: 24.w,
                    top: 29.h,
                    bottom: 18.h,
                  ),
                ),
                CategoriesListFilter(
                  categories: _categoriesList ?? [],
                  onCategorySelected: (value) {
                    _selectedTags = value;
                    _pagingController.value = PagingState(
                      nextPageKey: null,
                      error: null,
                      itemList: [],
                    );
                    bloc.add(
                      GetBlogHomeListEvent(
                        page: 1,
                        limit: 10,
                        tags: _selectedTags == 'همه' ? null : _selectedTags,
                        getCategories: _categoriesList != null ? false : true,
                        q: _serachBoxController.text.trim(),
                      ),
                    );
                  },
                ),
                SizedBox(height: 8.h),
                if (state is BlogHomeLoadingState)
                  Expanded(child: GlobalLoadingSection())
                else if (state is BlogHomeFailedState && isFirstPage)
                  Expanded(
                    child: GlobalErrorSection(
                      message: state.message,
                      onRetry: () {
                        bloc.add(
                          GetBlogHomeListEvent(
                            page: 1,
                            limit: 10,
                            tags: _selectedTags,
                            getCategories: _categoriesList != null
                                ? false
                                : true,
                            q: _serachBoxController.text.trim(),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Expanded(
                    child: PagedListView<int, Blog>(
                      shrinkWrap: true,
                      pagingController: _pagingController,
                      padding: EdgeInsets.only(bottom: 100.h),
                      builderDelegate: PagedChildBuilderDelegate<Blog>(
                        itemBuilder: (context, item, index) => GestureDetector(
                          onTap: () {
                            goScreen(
                              context: context,
                              screen: SingleBlogScreen(singleBlog: item),
                            );
                          },

                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            height: 155.h,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceDim,
                                  width: 1.w,
                                ),
                              ),
                            ),
                            padding: EdgeInsets.only(
                              left: 24.w,
                              right: 24.w,
                              top: 31.h,
                              bottom: 14.h,
                            ),

                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        item.title ?? "",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium!
                                            .copyWith(
                                              height: 1.5.h,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      SizedBox(height: 3.h),
                                      Text(
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        item.summary ?? "",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              height: 1.5.h,
                                              fontSize: 12.75.sp,
                                            ),
                                      ),
                                      Spacer(),
                                      Text(
                                        "${formatReminderDateTime(item.createdAt!)["date"]}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              height: 1.5.h,
                                              fontSize: 12.75.sp,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 17.w),
                                SizedBox(
                                  width: 87.w,
                                  height: 66.h,
                                  child: ClipRRect(
                                    borderRadius: BorderRadiusGeometry.circular(
                                      4.r,
                                    ),
                                    child: AppCachedImage(
                                      url:
                                          '${AppConstants.appImgBaseUrl}${item.image!}',
                                    ),
                                    //  Image.asset(
                                    //   "assets/images/dog_detail_sample.png",
                                    // ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        firstPageProgressIndicatorBuilder: (_) =>
                            GlobalLoadingSection(),

                        firstPageErrorIndicatorBuilder: (context) =>
                            GlobalErrorSection(
                              message: _pagingController.error!
                                  .toString()
                                  .replaceFirst('Exception: ', ''),
                              onRetry: _pagingController.retryLastFailedRequest,
                            ),
                        noItemsFoundIndicatorBuilder: (context) {
                          return SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: Center(
                              child: Text(
                                "no_blogs_found".tr(),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          );
                        },
                        transitionDuration: Duration(milliseconds: 300),
                        animateTransitions: true,

                        newPageProgressIndicatorBuilder: (_) =>
                            GlobalPaginationLoadingSection(),

                        newPageErrorIndicatorBuilder: (context) =>
                            GlobalPaginationErrorSection(
                              message: _pagingController.error
                                  .toString()
                                  .replaceFirst('Exception: ', ''),

                              onRetry: () {
                                if (state is BlogHomeFailedState) {
                                  final failedPageKey =
                                      _pagingController.nextPageKey ?? 1;
                                  bloc.add(
                                    GetBlogHomeListEvent(
                                      page: failedPageKey,
                                      limit: 10,
                                      tags: _selectedTags,
                                      getCategories: _categoriesList != null
                                          ? false
                                          : true,
                                      q: _serachBoxController.text.trim(),
                                    ),
                                  );
                                }
                              },
                            ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
