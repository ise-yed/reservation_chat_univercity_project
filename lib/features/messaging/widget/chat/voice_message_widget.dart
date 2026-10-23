import 'dart:async';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/utils/voice_player_manager.dart';
import 'package:reservation_chat_univercity_project/core/widgets/format_reminder_date.dart';

class VoiceMessageWidget extends StatefulWidget {
  final bool isMine;
  final bool isSeen;
  final String audioUrl;
  final String time;

  const VoiceMessageWidget({
    super.key,
    required this.isMine,
    required this.audioUrl,
    required this.time,
    this.isSeen = false,
  });

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget> {
  final VoicePlayerManager _playerManager = VoicePlayerManager.instance;
  StreamSubscription<PlayerStateData>? _playerStateSubscription;

  Duration _total = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isCurrentPlayer = false;

  @override
  void initState() {
    super.initState();
    // بدون ایجاد AudioPlayer اضافی در initState (جلوگیری از نشت منابع)؛
    // مدت زمان فایل صوتی به صورت Lazy در زمان پخش از استریم VoicePlayerManager خوانده می‌شود.
    _playerStateSubscription = _playerManager.playerStateStream.listen((
      playerState,
    ) {
      if (!mounted) return;
      final isThisPlayer =
          widget.audioUrl.isNotEmpty &&
          _playerManager.isCurrentUrl(widget.audioUrl);

      setState(() {
        _isCurrentPlayer = isThisPlayer;
        if (isThisPlayer) {
          _isPlaying = playerState.isPlaying;
          _position = playerState.position;
          if (playerState.duration > Duration.zero) {
            _total = playerState.duration;
          }
        } else {
          _isPlaying = false;
          _position = Duration.zero;
        }
      });
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: widget.isMine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Container(
          height: 72.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: widget.isMine
                ? Theme.of(context).colorScheme.shadow
                : AppColors.primary400,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  if (widget.audioUrl.isEmpty) return;
                  if (_isPlaying && _isCurrentPlayer) {
                    await _playerManager.pause();
                  } else {
                    await _playerManager.play(widget.audioUrl);
                  }
                },
                child: Container(
                  height: 42.h,
                  width: 42.w,
                  decoration: BoxDecoration(
                    color: widget.isMine
                        ? AppColors.primary400
                        : AppColors.text700Dark,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      _isCurrentPlayer && _isPlaying
                          ? Icons.pause
                          : Icons.play_arrow_rounded,
                      color: widget.isMine
                          ? AppColors.text700Dark
                          : AppColors.primary400,
                      size: 22,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: VoicePlayerBar(
                  isMine: widget.isMine,
                  progress: _position,
                  buffered: _position,
                  total: _total,
                  onSeek: (newPosition) {
                    if (_isCurrentPlayer) {
                      _playerManager.seek(newPosition);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isMine) ...[
              SvgPicture.asset(
                widget.isSeen
                    ? 'assets/icons/seen.svg'
                    : 'assets/icons/seen_one.svg',
                width: 20.w,
                height: 20.h,
                colorFilter: ColorFilter.mode(
                  widget.isSeen ? AppColors.primary400 : AppColors.text500Light,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 4.w),
            ],
            Text(
              formatReminderDateTime(widget.time)['time'] ?? '',
              style: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(fontSize: 11.25.sp),
            ),
          ],
        ),
      ],
    );
  }
}

class VoicePlayerBar extends StatelessWidget {
  final bool isMine;
  final Duration progress;
  final Duration buffered;
  final Duration total;
  final ValueChanged<Duration> onSeek;

  const VoicePlayerBar({
    super.key,
    required this.progress,
    required this.buffered,
    required this.total,
    required this.onSeek,
    required this.isMine,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final displayDuration = progress > Duration.zero ? progress : total;

    return Row(
      children: [
        Expanded(
          child: ProgressBar(
            barCapShape: BarCapShape.round,
            thumbCanPaintOutsideBar: false,
            thumbRadius: 0,
            progress: progress,
            buffered: buffered,
            bufferedBarColor: isMine
                ? AppColors.primary400.withOpacity(0.4)
                : AppColors.text700Dark.withOpacity(0.4),
            total: total,
            progressBarColor: isMine
                ? AppColors.primary400
                : AppColors.text700Dark,
            baseBarColor: Theme.of(context).colorScheme.onSurface
                .withOpacity(0.3),
            barHeight: 10.h,
            timeLabelLocation: TimeLabelLocation.none,
            onSeek: onSeek,
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          _formatDuration(displayDuration),
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontSize: 10.sp,
            color: isMine
                ? Theme.of(context).colorScheme.onSurface
                : AppColors.text700Dark,
          ),
        ),
      ],
    );
  }
}
