import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/utils/app_error.dart';
import 'package:reservation_chat_univercity_project/features/appointments/service/appointment_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentGatewayScreen extends StatefulWidget {
  final String payUrl;
  final String? paymentId;
  final String? doctorName;
  final String? offeringTitle;
  final String? amountText;

  const PaymentGatewayScreen({
    super.key,
    required this.payUrl,
    this.paymentId,
    this.doctorName,
    this.offeringTitle,
    this.amountText,
  });

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  final AppointmentServices _services = AppointmentServices();
  late String _currentPayUrl;
  bool _isProcessing = false;
  String? _resultStatus; // 'paid' | 'failed'
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentPayUrl = widget.payUrl;
  }

  Future<void> _handleVerifyMockGateway({required bool simulateFailure}) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await _services.verifyGatewayCallbackUrl(
        payUrl: _currentPayUrl,
        simulateFailure: simulateFailure,
      );
      final status = result['status']?.toString() ?? 'paid';
      setState(() {
        _resultStatus = status;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = getAppErrorMessage(e);
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleRetryPayment() async {
    if (widget.paymentId == null || widget.paymentId!.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final payment = await _services.startOnlinePayment(
        paymentId: widget.paymentId!,
      );
      setState(() {
        if (payment.payUrl != null && payment.payUrl!.isNotEmpty) {
          _currentPayUrl = payment.payUrl!;
        }
        _resultStatus = null;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = getAppErrorMessage(e);
        _isProcessing = false;
      });
    }
  }

  Future<void> _openInExternalBrowser() async {
    final uri = Uri.tryParse(_currentPayUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceContainerLowest,
          elevation: 0,
          title: Text(
            'درگاه پرداخت اینترنتی',
            style: textTheme.headlineMedium?.copyWith(
              fontSize: 16.5.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.onSurface),
            onPressed: () => Navigator.of(context).pop(_resultStatus == 'paid'),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // کارت خلاصه تراکنش
                Container(
                  padding: EdgeInsets.all(18.r),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.text200Light),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44.r,
                            height: 44.r,
                            decoration: BoxDecoration(
                              color: AppColors.primary50,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.security_rounded,
                              color: AppColors.primary500,
                              size: 24.r,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'پرداخت امن رزرو نوبت',
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontSize: 15.5.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'درگاه پرداخت آزمایشی (آماده اتصال به زرین‌پال)',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        child: Divider(
                          height: 1,
                          color: AppColors.text200Light,
                        ),
                      ),
                      if (widget.doctorName != null) ...[
                        _buildInfoRow(
                          context,
                          label: 'پزشک:',
                          value: widget.doctorName!,
                        ),
                        SizedBox(height: 8.h),
                      ],
                      if (widget.offeringTitle != null) ...[
                        _buildInfoRow(
                          context,
                          label: 'نوع خدمت:',
                          value: widget.offeringTitle!,
                        ),
                        SizedBox(height: 8.h),
                      ],
                      if (widget.amountText != null)
                        _buildInfoRow(
                          context,
                          label: 'مبلغ قابل پرداخت:',
                          value: '${widget.amountText} تومان',
                          isBold: true,
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                if (_errorMessage != null) ...[
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppColors.statusCancelledBg,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.statusCancelledFg,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                // وضعیت نتیجه پرداخت
                if (_resultStatus == 'paid')
                  _buildResultCard(
                    context,
                    isSuccess: true,
                    title: 'پرداخت با موفقیت انجام شد',
                    subtitle: 'نوبت شما در سیستم ثبت و نهایی گردید. اکنون می‌توانید جزئیات آن را در بخش نوبت‌های من مشاهده کنید.',
                  )
                else if (_resultStatus == 'failed')
                  _buildResultCard(
                    context,
                    isSuccess: false,
                    title: 'پرداخت ناموفق بود',
                    subtitle: 'تراکنش تایید نشد. نوبت شما به مدت ۱۵ دقیقه رزرو موقت شده و می‌توانید مجدداً پرداخت را انجام دهید.',
                  )
                else ...[
                  Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      'از آنجایی که درگاه زرین‌پال هنوز احراز هویت نشده، بک‌اند روی MockGateway تنظیم شده است. می‌توانید پرداخت موفق یا ناموفق را مستقیماً تست کنید یا لینک درگاه را در مرورگر باز نمایید.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                if (_isProcessing)
                  const Center(child: CircularProgressIndicator())
                else if (_resultStatus == 'paid')
                  SizedBox(
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary500,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: const Text('بازگشت و مشاهده نوبت‌ها'),
                    ),
                  )
                else if (_resultStatus == 'failed')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.paymentId != null)
                        SizedBox(
                          height: 48.h,
                          child: ElevatedButton.icon(
                            onPressed: _handleRetryPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary500,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('تلاش مجدد برای پرداخت'),
                          ),
                        ),
                      SizedBox(height: 10.h),
                      SizedBox(
                        height: 46.h,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('بازگشت'),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 48.h,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _handleVerifyMockGateway(simulateFailure: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary500,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('تایید و تکمیل پرداخت آنلاین'),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46.h,
                              child: OutlinedButton.icon(
                                onPressed: () => _handleVerifyMockGateway(
                                  simulateFailure: true,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.statusCancelledFg,
                                  side: const BorderSide(
                                    color: AppColors.statusCancelledFg,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                icon: const Icon(Icons.cancel_outlined),
                                label: const Text('شبیه‌سازی خطا'),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: SizedBox(
                              height: 46.h,
                              child: OutlinedButton.icon(
                                onPressed: _openInExternalBrowser,
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: const Text('باز کردن در مرورگر'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isBold = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: isBold ? AppColors.primary500 : AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(
    BuildContext context, {
    required bool isSuccess,
    required String title,
    required String subtitle,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final bgColor = isSuccess
        ? AppColors.statusConfirmedBg
        : AppColors.statusCancelledBg;
    final fgColor = isSuccess
        ? AppColors.statusConfirmedFg
        : AppColors.statusCancelledFg;

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(
            isSuccess ? Icons.verified_rounded : Icons.error_outline_rounded,
            size: 44.r,
            color: fgColor,
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            style: textTheme.headlineMedium?.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: fgColor,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurface,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
