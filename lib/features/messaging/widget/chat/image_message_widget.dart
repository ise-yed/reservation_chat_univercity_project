import 'dart:io'
    if (dart.library.html) 'package:reservation_chat_univercity_project/core/utils/io_stub.dart'
    as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/utils/navigator.dart';
import 'package:reservation_chat_univercity_project/core/widgets/app_cached_image.dart';
import 'package:reservation_chat_univercity_project/core/widgets/format_reminder_date.dart';
import 'package:reservation_chat_univercity_project/features/messaging/screens/image_viewer.dart';

class ImageMessageWidget extends StatelessWidget {
  final String imageUrl;
  final String? localFilePath;
  final String time;
  final bool isMine;
  final bool isSeen;

  const ImageMessageWidget({
    super.key,
    required this.isMine,
    required this.imageUrl,
    required this.time,
    this.localFilePath,
    this.isSeen = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasNetworkUrl = imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: hasNetworkUrl
          ? () {
              goScreen(
                context: context,
                screen: FullImageView(imageUrl: imageUrl),
              );
            }
          : null,
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.28,
            width: MediaQuery.of(context).size.width * 0.6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.r),
                topRight: Radius.circular(isMine ? 5.r : 18.r),
                bottomRight: Radius.circular(18.r),
                bottomLeft: Radius.circular(isMine ? 18.r : 5.r),
              ),
              color: isMine
                  ? Theme.of(context).colorScheme.shadow
                  : AppColors.primary400,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18.r),
                topRight: Radius.circular(isMine ? 5.r : 18.r),
                bottomRight: Radius.circular(18.r),
                bottomLeft: Radius.circular(isMine ? 18.r : 5.r),
              ),
              child: hasNetworkUrl
                  ? AppCachedImage(url: imageUrl, fit: BoxFit.cover)
                  : (!kIsWeb &&
                        localFilePath != null &&
                        localFilePath!.isNotEmpty)
                  ? Image.file(io.File(localFilePath!), fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.image_outlined)),
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: isMine
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (isMine) ...[
                SvgPicture.asset(
                  isSeen
                      ? 'assets/icons/seen.svg'
                      : 'assets/icons/seen_one.svg',
                  width: 20.w,
                  height: 20.h,
                  colorFilter: ColorFilter.mode(
                    isSeen ? AppColors.primary400 : AppColors.text500Light,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(width: 4.w),
              ],
              Text(
                formatReminderDateTime(time)['time'] ?? '',
                style: Theme.of(context).textTheme.bodyMedium!
                    .copyWith(fontSize: 11.25.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
