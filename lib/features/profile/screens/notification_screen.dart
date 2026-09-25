import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_error_section.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_loading_section.dart';
import 'package:reservation_chat_univercity_project/core/widgets/pagination_error.dart';
import 'package:reservation_chat_univercity_project/core/widgets/pagination_indicator.dart';
import 'package:reservation_chat_univercity_project/features/profile/bloc/profile_bloc.dart';
import 'package:reservation_chat_univercity_project/features/profile/model/notification_model.dart';
import 'package:reservation_chat_univercity_project/features/profile/widgets/notification/notification_item_widget.dart';
import 'package:reservation_chat_univercity_project/core/widgets/reminders_appbar_widget.dart';
import 'package:flutter/widgets.dart' as ui;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final PagingController<int, NotificationDoc> _pagingController =
      PagingController(firstPageKey: 1);

  int listLimit = 10;

  @override
  void initState() {
    super.initState();
    final bloc = BlocProvider.of<ProfileBloc>(context);
    bloc.add(NotificationDataEvent(page: 1, limit: 2, callSeen: true));
    _pagingController.addPageRequestListener((pageKey) {
      bloc.add(
        NotificationDataEvent(
          page: pageKey,
          limit: listLimit,
          callSeen: pageKey == 1 ? true : false,
        ),
      );
    });

    // BlocProvider.of<ProfileBloc>(context).add(SeenNotificationEvent());
  }

  @override
  Widget build(BuildContext context) {
    final bool isRTL = Directionality.of(context) == ui.TextDirection.rtl;
    final bloc = BlocProvider.of<ProfileBloc>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            RemindersAppbarWidget(
              title: "notifications".tr(),
              leadingIcon: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.pop(context);
                },
                child: RotatedBox(
                  quarterTurns: isRTL ? 0 : 2,
                  child: SvgPicture.asset(
                    "assets/icons/arrow-right.svg",
                    width: 24.w,
                    height: 24.h,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.onSurface,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),

            BlocConsumer<ProfileBloc, ProfileState>(
              buildWhen: (previous, current) =>
                  current is NotificationDataLoadingState ||
                  current is NotificationDataSuccessState ||
                  current is NotificationDataFailedState,
              listener: (context, state) {
                if (state is NotificationDataSuccessState) {
                  final dataModel = state.notificationModel;
                  // !most check null
                  // todo: must check null
                  final newItems = dataModel!.docs;
                  // final unseenItems = newItems.where((e) => e.seen == false).toList();

                  // if (unseenItems.isNotEmpty) {
                  // BlocProvider.of<ProfileBloc>(context).add(
                  //   SeenNotificationEvent(
                  //     // ids: unseenItems.map((e) => e.id).toList(),
                  //   ),
                  // );
                  // }
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
                } else if (state is NotificationDataFailedState) {
                  _pagingController.error = state.message;
                }
              },
              builder: (context, state) {
                if (state is NotificationDataLoadingState) {
                  return Expanded(child: GlobalLoadingSection());
                } else if (state is NotificationDataFailedState) {
                  return Expanded(
                    child: GlobalErrorSection(
                      message: state.message,
                      onRetry: () {
                        bloc.add(
                          NotificationDataEvent(
                            page: 1,
                            limit: listLimit,
                            callSeen: true,
                          ),
                        );
                      },
                    ),
                  );
                } else {
                  return Expanded(
                    child: PagedListView<int, NotificationDoc>(
                      shrinkWrap: true,
                      pagingController: _pagingController,
                      padding: EdgeInsets.only(bottom: 100.h),
                      builderDelegate:
                          PagedChildBuilderDelegate<NotificationDoc>(
                            itemBuilder: (context, item, index) =>
                                NotificationsItemWidget(
                                  isActive: true,
                                  notificationdata: item,
                                ),

                            firstPageProgressIndicatorBuilder: (_) =>
                                GlobalLoadingSection(),

                            firstPageErrorIndicatorBuilder: (context) =>
                                GlobalErrorSection(
                                  message: _pagingController.error!
                                      .toString()
                                      .replaceFirst('Exception: ', ''),
                                  onRetry:
                                      _pagingController.retryLastFailedRequest,
                                ),
                            noItemsFoundIndicatorBuilder: (context) {
                              return SizedBox(
                                width: MediaQuery.of(context).size.width,
                                height:
                                    MediaQuery.of(context).size.height * 0.4,
                                child: Center(
                                  child: Text(
                                    "notif_empty".tr(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
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
                                    if (state is NotificationDataFailedState) {
                                      final failedPageKey =
                                          _pagingController.nextPageKey ?? 1;

                                      bloc.add(
                                        NotificationDataEvent(
                                          page: failedPageKey,
                                          limit: listLimit,
                                        ),
                                      );
                                    }
                                  },
                                ),
                          ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
