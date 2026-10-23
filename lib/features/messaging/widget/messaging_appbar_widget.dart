import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_setting.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/utils/search_box_widget.dart';
import 'package:reservation_chat_univercity_project/core/widgets/reminders_appbar_widget.dart';

class MessagingAppbarWidget extends StatelessWidget {
  final String appbarTitle;
  final bool haveBackButton;
  final bool haveFilter;
  final VoidCallback? onCloseTapSearch;
  final VoidCallback? onFilterTapSearch;
  final TextEditingController? searchTextEditingController;
  final ValueChanged<String>? onChangedSearch;

  const MessagingAppbarWidget({
    super.key,
    required this.appbarTitle,
    this.haveFilter = false,
    this.haveBackButton = false,
    this.onCloseTapSearch,
    this.onFilterTapSearch,
    this.searchTextEditingController,
    this.onChangedSearch,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRTL = Directionality.of(context) == ui.TextDirection.rtl;
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.fill,
          image: isThemeLight.value
              ? const AssetImage('assets/images/appbar_chat2.png')
              : const AssetImage('assets/images/appbar_chat1.png'),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, kIsWeb ? 0 : 24.w, 24.w, 0.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RemindersAppbarWidget(
              titleAppbar: Theme.of(context).textTheme.headlineMedium!
                  .copyWith(fontSize: 17.5.sp, color: AppColors.text700Dark),
              horizontalPadding: 0,
              title: appbarTitle.tr(),
              leadingIcon: haveBackButton
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.pop(context),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..scale(isRTL ? 1.0 : -1.0, 1.0),
                        child: SvgPicture.asset(
                          'assets/icons/arrow-right.svg',
                          width: 24.w,
                          height: 24.h,
                          colorFilter: const ColorFilter.mode(
                            AppColors.text700Dark,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(height: 6.h),
            SearchBoxWidget(
              haveFilter: haveFilter,
              onChanged: onChangedSearch,
              onCloseTap: onCloseTapSearch,
              onFilterTap: onFilterTapSearch,
              controller:
                  searchTextEditingController ?? TextEditingController(),
              backColor: Theme.of(context).colorScheme.shadow,
              margin: EdgeInsets.zero,
            ),
            SizedBox(height: 18.h),
          ],
        ),
      ),
    );
  }
}
