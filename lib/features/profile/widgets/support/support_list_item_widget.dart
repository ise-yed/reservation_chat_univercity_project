import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as ui;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/utils/navigator.dart';
import 'package:reservation_chat_univercity_project/features/profile/model/ticket_list_model.dart';

// import 'package:reservation_chat_univercity_project/features/profile/screens/messaging_ticket_screen.dart';

enum SupportState { success, failed, progress }

class SupportListItemWidget extends StatelessWidget {
  final TicketListModel ticketModel;

  const SupportListItemWidget({super.key, required this.ticketModel});

  Widget setSubtextState(String state, BuildContext context) {
    switch (state) {
      case "answered":
        return Text(
          "support_subtext_answered".tr(),
          style: Theme.of(context).textTheme.bodySmall!
              .copyWith(color: AppColors.subtextGreen),
        );

      case "closed":
        return Text(
          "support_subtext_closed".tr(),
          style: Theme.of(context).textTheme.bodySmall!
              .copyWith(color: AppColors.subtextRed),
        );
      case "pending":
        return Text(
          "support_subtext_inPorgress".tr(),
          style: Theme.of(context).textTheme.bodySmall!
              .copyWith(color: AppColors.subtextBlue),
        );
    }
    return Text(
      "unknown".tr(),
      style: Theme.of(context).textTheme.bodySmall!
          .copyWith(color: AppColors.subtextBlue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isRTL = Directionality.of(context) == ui.TextDirection.rtl;
    return InkWell(
      onTap: () {
        // goScreen(
        //   context: context,
        //   screen: MessagingTicketScreen(
        //     ticketModel: ticketModel,
        //     fromTicket: true,
        //   ),
        // );
      },
      child: Container(
        height: 100.h,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),

        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.secondaryFixed,
              ),
              height: 68.r,
              width: 68.r,
              child: Center(
                child: SvgPicture.asset(
                  "assets/icons/headphones.svg",
                  width: 24.w,
                  height: 24.h,
                  colorFilter: ColorFilter.mode(
                    Color(0xFF0498FF),

                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticketModel.subject ?? "unknown".tr(),
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(),
                  ),
                  SizedBox(height: 12.h),
                  setSubtextState(ticketModel.status!, context),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            RotatedBox(
              quarterTurns: isRTL ? 0 : 2,
              child: SvgPicture.asset(
                "assets/icons/direction-left 2.svg",
                width: 24.w,
                height: 24.h,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.onSecondary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
