import 'dart:async';
import 'dart:io'
    if (dart.library.html) 'package:reservation_chat_univercity_project/core/utils/io_stub.dart'
    as io;

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as ui;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reservation_chat_univercity_project/core/utils/image_handler.dart';
import 'package:reservation_chat_univercity_project/core/utils/snakbar.dart';
import 'package:reservation_chat_univercity_project/core/widgets/main_textfield.dart';
import 'package:reservation_chat_univercity_project/features/messaging/bloc/chat_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:toastification/toastification.dart';

class ChatBottomSectionChat extends StatefulWidget {
  final String conversationId;
  final bool isSendingAllowed;
  final String? lockReason;
  final VoidCallback? onBookNewAppointmentTap;
  final void Function(String text)? onSendText;
  final void Function(String filePath, String fileName)? onSendImageFile;
  final void Function(String filePath, String fileName)? onSendDocumentFile;
  final void Function(String filePath, String fileName)? onSendVoiceFile;

  const ChatBottomSectionChat({
    super.key,
    required this.conversationId,
    this.isSendingAllowed = true,
    this.lockReason,
    this.onBookNewAppointmentTap,
    this.onSendText,
    this.onSendImageFile,
    this.onSendDocumentFile,
    this.onSendVoiceFile,
  });

  @override
  State<ChatBottomSectionChat> createState() => _ChatBottomSectionChatState();
}

class _ChatBottomSectionChatState extends State<ChatBottomSectionChat> {
  final TextEditingController _messageTextController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImageHandler _imagePicker = ImageHandler();

  String _lastText = '';
  bool _hasText = false;
  bool _isRecordingVoice = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _recordingTempPath;
  String? _recordingFileName;

  @override
  void initState() {
    super.initState();
    _messageTextController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageTextController.removeListener(_onTextChanged);
    _messageTextController.dispose();
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _messageTextController.text;
    final bloc = context.read<ChatBloc>();

    if (_lastText.isEmpty && text.isNotEmpty) {
      bloc.add(const SendTypingStatusEvent(isTyping: true));
    } else if (_lastText.isNotEmpty && text.isEmpty) {
      bloc.add(const SendTypingStatusEvent(isTyping: false));
    }

    final hasTextNow = text.trim().isNotEmpty;
    if (hasTextNow != _hasText && mounted) {
      setState(() => _hasText = hasTextNow);
    }
    _lastText = text;
  }

  void _sendTextMessage() {
    final text = _messageTextController.text.trim();
    if (text.isEmpty) return;
    widget.onSendText?.call(text);
    _messageTextController.clear();
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet<void>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text(
                  'ارسال تصویر (JPG / PNG / WEBP - حداکثر ۵ مگابایت)',
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text(
                  'ارسال مدرک یا آزمایش (PDF - حداکثر ۱۰ مگابایت)',
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickPdfDocument();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    await _imagePicker.pickAndCompressImage(source: ImageSource.gallery);
    final picked = _imagePicker.getImage;
    if (picked == null || picked.path.isEmpty) return;

    widget.onSendImageFile?.call(picked.path, picked.name);
  }

  Future<void> _pickPdfDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (result == null || result.isEmpty) return;
    final file = result.single;
    if (file.path == null || file.path!.isEmpty) return;

    widget.onSendDocumentFile?.call(file.path!, file.name);
  }

  Future<void> _startRecording() async {
    if (kIsWeb) return;
    try {
      final hasPerm = await _audioRecorder.hasPermission();
      if (!hasPerm) {
        if (!mounted) return;
        showCustomSnackBar(
          context: context,
          title: 'خطا',
          content: 'دسترسی به میکروفون داده نشده است.',
          status: ToastificationType.error,
        );
        return;
      }

      final isAndroid = defaultTargetPlatform == TargetPlatform.android;
      final fileName =
          'voice_${DateTime.now().millisecondsSinceEpoch}.${isAndroid ? 'wav' : 'm4a'}';
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$fileName';

      final config = isAndroid
          ? const RecordConfig(
              encoder: AudioEncoder.wav,
              sampleRate: 44100,
              numChannels: 1,
            )
          : const RecordConfig(
              encoder: AudioEncoder.aacLc,
              bitRate: 128000,
              sampleRate: 44100,
              numChannels: 1,
            );

      await _audioRecorder.start(config, path: path);
      _recordingTempPath = path;
      _recordingFileName = fileName;

      if (mounted) {
        setState(() {
          _isRecordingVoice = true;
          _recordSeconds = 0;
        });
      }

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!mounted) return;
        final isRec = await _audioRecorder.isRecording();
        if (!isRec) {
          timer.cancel();
          return;
        }
        setState(() => _recordSeconds++);
      });
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        title: 'خطا',
        content: e.toString(),
        status: ToastificationType.error,
      );
    }
  }

  Future<void> _stopRecording({required bool cancel}) async {
    try {
      _recordTimer?.cancel();
      String? outPath;
      if (await _audioRecorder.isRecording()) {
        outPath = await _audioRecorder.stop();
      }
      final finalPath = outPath ?? _recordingTempPath;

      if (cancel) {
        if (finalPath != null && await io.File(finalPath).exists()) {
          try {
            await io.File(finalPath).delete();
          } catch (_) {}
        }
      } else if (finalPath != null && finalPath.isNotEmpty) {
        widget.onSendVoiceFile?.call(
          finalPath,
          _recordingFileName ?? 'voice.m4a',
        );
      }
    } finally {
      _recordingTempPath = null;
      _recordingFileName = null;
      if (mounted) {
        setState(() {
          _isRecordingVoice = false;
          _recordSeconds = 0;
        });
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  String _resolveLockBannerMessage(String? reason) {
    return switch (reason) {
      'not_started' => 'زمان نوبت آنلاین شما هنوز فرا نرسیده است. در زمان شروع نوبت، ارسال پیام فعال خواهد شد.',
      'pending' => 'نوبت شما در انتظار تأیید است. پس از تأیید و شروع زمان نوبت می‌توانید پیام ارسال کنید.',
      'cancelled' => 'این نوبت لغو شده است.',
      _ => 'زمان ویزیت آنلاین شما به پایان رسیده است. شما همچنان می‌توانید پیام‌ها و نسخه‌های پزشک را دریافت کنید، اما برای ارسال پیام جدید یا جواب آزمایش، نوبت جدیدی رزرو نمایید.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // اگر بیمار خارج از بازه زمانی نوبت آنلاین باشد، بنر قفل نمایش داده می‌شود
    if (!widget.isSendingAllowed) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.lock_clock_outlined, color: cs.primary, size: 22.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    _resolveLockBannerMessage(widget.lockReason),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
            if (widget.onBookNewAppointmentTap != null) ...[
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onBookNewAppointmentTap,
                  child: const Text('رزرو نوبت مجدد با این پزشک'),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final bool isRTL = Directionality.of(context) == ui.TextDirection.rtl;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      color: cs.shadow,
      height: 83.h,
      child: Row(
        children: [
          if (_isRecordingVoice)
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                height: 56.h,
                decoration: BoxDecoration(
                  color: cs.surfaceBright,
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _stopRecording(cancel: true),
                      behavior: HitTestBehavior.opaque,
                      child: SvgPicture.asset(
                        'assets/icons/trash_fill.svg',
                        width: 24.w,
                        height: 24.h,
                        colorFilter: ColorFilter.mode(
                          cs.onSecondary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatDuration(_recordSeconds),
                            style: Theme.of(context).textTheme.headlineMedium!
                                .copyWith(height: 1.5.h, fontSize: 14.sp),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            height: 8.r,
                            width: 8.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _stopRecording(cancel: false),
                      child: RotatedBox(
                        quarterTurns: isRTL ? 0 : 2,
                        child: SvgPicture.asset(
                          'assets/icons/sent-fast.svg',
                          width: 24.w,
                          height: 24.h,
                          colorFilter: ColorFilter.mode(
                            cs.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Expanded(
              child: CoreTextFieldNormal(
                suffix: _hasText
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _sendTextMessage,
                        child: RotatedBox(
                          quarterTurns: isRTL ? 0 : 2,
                          child: SvgPicture.asset(
                            'assets/icons/sent-fast.svg',
                            width: 24.w,
                            height: 24.h,
                            colorFilter: ColorFilter.mode(
                              cs.primary,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      )
                    : null,
                focusBorderColor: cs.surfaceDim,
                textFieldborderRadius: 18,
                controller: _messageTextController,
                hint: 'chat_hint'.tr(),
              ),
            ),
            if (!_hasText) ...[
              SizedBox(width: 6.w),
              GestureDetector(
                onTap: () => _showAttachmentOptions(context),
                child: Container(
                  height: 56.h,
                  width: 56.w,
                  decoration: BoxDecoration(
                    color: cs.surfaceBright,
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/attachment.svg',
                      width: 24.w,
                      height: 24.h,
                      colorFilter: ColorFilter.mode(
                        cs.tertiary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
              if (!kIsWeb) ...[
                SizedBox(width: 6.w),
                GestureDetector(
                  onTap: _startRecording,
                  child: Container(
                    height: 56.h,
                    width: 56.w,
                    decoration: BoxDecoration(
                      color: cs.surfaceBright,
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/microphone.svg',
                        width: 24.w,
                        height: 24.h,
                        colorFilter: ColorFilter.mode(
                          cs.tertiary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}
