import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_setting.dart';
import 'package:reservation_chat_univercity_project/core/utils/navigator.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_error_section.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_loading_section.dart';
import 'package:reservation_chat_univercity_project/features/messaging/bloc/chat_bloc.dart';
import 'package:reservation_chat_univercity_project/features/messaging/screens/messaging_chat_screen.dart';
import 'package:reservation_chat_univercity_project/features/messaging/service/models/conversation_model.dart';
import 'package:reservation_chat_univercity_project/features/messaging/widget/messaging_appbar_widget.dart';
import 'package:reservation_chat_univercity_project/features/messaging/widget/messaging_empty_state.dart';
import 'package:reservation_chat_univercity_project/features/profile/utils/format_chat_time_utils.dart';

class MessagingHomeScreen extends StatefulWidget {
  const MessagingHomeScreen({super.key});

  @override
  State<MessagingHomeScreen> createState() => _MessagingHomeScreenState();
}

class _MessagingHomeScreenState extends State<MessagingHomeScreen> {
  final TextEditingController _searchBoxController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(
      const LoadConversationsEvent(page: 1, refresh: true),
    );
  }

  @override
  void dispose() {
    _searchBoxController.dispose();
    super.dispose();
  }

  String get _myUserId => (currentUserModel.id ?? '').toString();

  List<ConversationModel> _filterConversations(List<ConversationModel> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all.where((conv) {
      final peer = conv.getPeerUser(_myUserId);
      final nameMatch = peer.displayName.toLowerCase().contains(q);
      final msgMatch =
          (conv.lastMessage?.inboxPreviewText.toLowerCase().contains(q) ??
          false);
      return nameMatch || msgMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          final filteredList = _filterConversations(state.conversations);

          return Column(
            children: [
              MessagingAppbarWidget(
                searchTextEditingController: _searchBoxController,
                appbarTitle: 'گفت‌وگوهای پزشکی',
                haveFilter: false,
                haveBackButton: false,
                onCloseTapSearch: () {
                  _searchBoxController.clear();
                  setState(() => _searchQuery = '');
                },
                onChangedSearch: (value) {
                  setState(() => _searchQuery = value.trim());
                },
              ),
              if (state.isLoadingConversations && state.conversations.isEmpty)
                Expanded(child: GlobalLoadingSection())
              else if (state.inboxError != null && state.conversations.isEmpty)
                Expanded(
                  child: GlobalErrorSection(
                    message: state.inboxError!,
                    onRetry: () {
                      context.read<ChatBloc>().add(
                        const LoadConversationsEvent(page: 1, refresh: true),
                      );
                    },
                  ),
                )
              else if (filteredList.isEmpty)
                const Expanded(child: MessagingEmptyStateWidget())
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<ChatBloc>().add(
                        const LoadConversationsEvent(page: 1, refresh: true),
                      );
                    },
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      itemCount: filteredList.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1.h,
                        color: cs.outlineVariant.withOpacity(0.3),
                      ),
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        final peer = item.getPeerUser(_myUserId);
                        final lastMsg = item.lastMessage;
                        final lastTimeStr = lastMsg != null
                            ? lastMsg.createdAt.toIso8601String()
                            : item.updatedAt.toIso8601String();

                        return InkWell(
                          onTap: () async {
                            await goScreen(
                              context: context,
                              screen: MessagingChatScreen(
                                conversationId: item.id,
                                initialConversation: item,
                              ),
                            );
                            if (context.mounted) {
                              context.read<ChatBloc>().add(
                                const LoadConversationsEvent(
                                  page: 1,
                                  refresh: true,
                                ),
                              );
                            }
                          },
                          child: Container(
                            height: 92.h,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28.r,
                                  backgroundColor: cs.primaryContainer,
                                  child: Text(
                                    peer.displayName.isNotEmpty
                                        ? peer.displayName.characters.first
                                        : '؟',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: cs.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              peer.displayName,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineMedium!
                                                  .copyWith(fontSize: 14.sp),
                                            ),
                                          ),
                                          if (peer.isProvider)
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8.w,
                                                vertical: 2.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: cs.primary.withOpacity(
                                                  0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                              ),
                                              child: Text(
                                                'پزشک',
                                                style: TextStyle(
                                                  fontSize: 10.sp,
                                                  color: cs.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        lastMsg?.inboxPreviewText ??
                                            'گفت‌وگو آغاز شده است',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              fontSize: 12.5.sp,
                                              fontStyle:
                                                  lastMsg?.isDeleted == true
                                                  ? FontStyle.italic
                                                  : FontStyle.normal,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (item.unreadCount > 0)
                                      SizedBox(
                                        height: 24.h,
                                        width: 24.w,
                                        child: badges.Badge(
                                          showBadge: true,
                                          badgeContent: Center(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                '${item.unreadCount}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11.sp,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          badgeStyle: badges.BadgeStyle(
                                            shape: badges.BadgeShape.circle,
                                            badgeColor: cs.primary,
                                            padding: EdgeInsets.zero,
                                          ),
                                          position:
                                              badges.BadgePosition.center(),
                                        ),
                                      )
                                    else if (lastMsg != null &&
                                        lastMsg.isMine(_myUserId))
                                      SvgPicture.asset(
                                        'assets/icons/seen.svg',
                                        width: 18.w,
                                        height: 18.h,
                                        colorFilter: ColorFilter.mode(
                                          cs.primary,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      formatChatTime(lastTimeStr),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall!
                                          .copyWith(
                                            fontWeight: FontWeight.w400,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
