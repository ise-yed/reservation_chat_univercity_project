// import 'dart:io';

// import 'package:flutter/foundation.dart';
// import 'package:myket_iap/myket_iap.dart';
// import 'package:myket_iap/util/iab_result.dart';
// import 'package:myket_iap/util/purchase.dart';
// import 'package:flutter_poolakey/flutter_poolakey.dart';
// import 'package:reservation_chat_univercity_project/core/constants/app_constants.dart';
// import 'package:reservation_chat_univercity_project/core/payments/zarinpal_pending_store.dart';

// import 'package:url_launcher/url_launcher.dart';

// class PaymentResult {
//   final bool success;

//   /// User canceled the payment flow (IAP cancel, etc.)
//   final bool canceled;

//   /// For gateways like Zarinpal: payment is started and app must wait for deep-link callback.
//   final bool pending;

//   final String? message;

//   const PaymentResult({
//     required this.success,
//     this.canceled = false,
//     this.pending = false,
//     this.message,
//   });
// }

// abstract class PaymentGateway {
//   Future<PaymentResult> purchasePlan(PremiumPlanModel plan);
// }

// class MyketPaymentGateway implements PaymentGateway {
//   final PremiumServices _premiumServices;
//   static bool _initialized = false;

//   MyketPaymentGateway(this._premiumServices);

//   Future<void> _ensureInitialized() async {
//     if (_initialized) return;

//     final IabResult? result = await MyketIAP.init(
//       rsaKey: AppConstants.myketRsaKey,
//       enableDebugLogging: kDebugMode,
//     );
//     if (result != null && result.isFailure()) {
//       throw Exception('Myket init failed: ${result.mMessage}');
//     }
//     _initialized = true;
//   }

//   @override
//   Future<PaymentResult> purchasePlan(PremiumPlanModel plan) async {
//     try {
//       if (plan.id == null || plan.marketId == null) {
//         return const PaymentResult(
//           success: false,
//           message: 'payment.plan_incomplete',
//         );
//       }

//       await _ensureInitialized();

//       // 1) ساخت تراکنش در بک‌اند
//       final transactionId = await _premiumServices.createMyketTransaction(
//         plan.id!,
//       );

//       // 2) شروع خرید در مایکت
//       final Map result = await MyketIAP.launchPurchaseFlow(
//         sku: plan.marketId!,
//         payload: transactionId,
//       );

//       final IabResult? iabResult = result[MyketIAP.RESULT] as IabResult?;
//       final Purchase? purchase = result[MyketIAP.PURCHASE] as Purchase?;

//       if (iabResult == null) {
//         return const PaymentResult(
//           success: false,
//           message: 'payment.invalid_response',
//         );
//       }

//       // 0 => OK, 1 => USER_CANCELED, بقیه خطا
//       if (iabResult.mResponse != 0) {
//         if (iabResult.mResponse == 1) {
//           return const PaymentResult(
//             success: false,
//             canceled: true,
//             message: 'payment.user_canceled',
//           );
//         }

//         return const PaymentResult(
//           success: false,
//           message: 'payment.myket_error_generic',
//         );
//       }

//       if (purchase == null) {
//         return const PaymentResult(
//           success: false,
//           message: 'payment.purchase_not_found',
//         );
//       }

//       // 3) وریفای در بک‌اند (اینجا اشتراک کاربر فعال می‌شود)
//       await _premiumServices.verifyMyketTransaction(
//         packageName: purchase.mPackageName,
//         skuId: purchase.mSku,
//         tokenId: purchase.mToken,
//       );

//       // 4) مصرف خرید در مایکت تا دوباره قابل خرید باشد
//       try {
//         final Map consumeResultMap = await MyketIAP.consume(purchase: purchase);

//         final IabResult? consumeResult =
//             consumeResultMap[MyketIAP.RESULT] as IabResult?;

//         if (consumeResult != null && consumeResult.isFailure()) {
//           if (kDebugMode) {
//             print(
//               'Myket consume failed: ${consumeResult.mMessage} (${consumeResult.mResponse})',
//             );
//           }
//         } else {
//           if (kDebugMode) {
//             print('Myket consume success for sku ${purchase.mSku}');
//           }
//         }
//       } catch (e, st) {
//         if (kDebugMode) {
//           print('Myket consume exception: $e\n$st');
//         }
//       }

//       return const PaymentResult(success: true, message: 'payment.success');
//     } catch (e, st) {
//       if (kDebugMode) {
//         print('Myket purchase error: $e\n$st');
//       }
//       return const PaymentResult(
//         success: false,
//         message: 'payment.process_error',
//       );
//     }
//   }
// }

// class BazaarPaymentGateway implements PaymentGateway {
//   final PremiumServices _premiumServices;

//   static bool _connected = false;
//   static bool _connecting = false;

//   BazaarPaymentGateway(this._premiumServices);

//   void connectIfNeeded() {
//     if (_connected || _connecting) return;

//     _connecting = true;

//     FlutterPoolakey.connect(
//       AppConstants.bazaarRsaKey,
//       onSucceed: () {
//         _connected = true;
//         _connecting = false;
//         if (kDebugMode) {
//           print('Bazaar connect: success');
//         }
//       },
//       onFailed: () {
//         _connected = false;
//         _connecting = false;
//         if (kDebugMode) {
//           print('Bazaar connect: failed');
//         }
//       },
//       onDisconnected: () {
//         _connected = false;
//         if (kDebugMode) {
//           print('Bazaar connect: disconnected');
//         }
//       },
//     );
//   }

//   bool get isConnected => _connected;

//   @override
//   Future<PaymentResult> purchasePlan(PremiumPlanModel plan) async {
//     // 0) چک کردن پلن
//     if (plan.id == null || plan.marketId == null) {
//       return const PaymentResult(
//         success: false,
//         message: 'payment.plan_incomplete',
//       );
//     }

//     // 1) اگر هنوز وصل نشده‌ایم، طبق داک رسمی نباید خرید بزنیم
//     if (!_connected) {
//       return const PaymentResult(
//         success: false,
//         message: 'payment.bazaar_not_connected',
//       );
//     }

//     try {
//       // 2) ساخت تراکنش در بک‌اند
//       final String transactionId = await _premiumServices
//           .createBazaarTransaction(plan.id!);

//       // 3) شروع خرید در بازار
//       PurchaseInfo? purchase;
//       try {
//         purchase = await FlutterPoolakey.purchase(
//           plan.marketId!,
//           payload: transactionId,
//           dynamicPriceToken: '',
//         );
//       } catch (e, st) {
//         if (kDebugMode) {
//           print('Bazaar purchase exception: $e\n$st');
//         }

//         final msg = e.toString();
//         if (msg.contains('CANCELED') || msg.contains('USER_CANCELED')) {
//           return const PaymentResult(
//             success: false,
//             canceled: true,
//             message: 'payment.user_canceled',
//           );
//         }

//         return const PaymentResult(
//           success: false,
//           message: 'payment.bazaar_error_generic',
//         );
//       }

//       if (purchase == null) {
//         return const PaymentResult(
//           success: false,
//           message: 'payment.purchase_not_found',
//         );
//       }

//       // 4) وریفای در بک‌اند
//       await _premiumServices.verifyBazaarTransaction(
//         packageName: purchase.packageName,
//         skuId: purchase.productId,
//         tokenId: purchase.purchaseToken,
//       );

//       // 5) مصرف (consume) برای قابل خرید شدن مجدد
//       try {
//         await FlutterPoolakey.consume(purchase.purchaseToken);
//       } catch (e, st) {
//         if (kDebugMode) {
//           print('Bazaar consume exception: $e\n$st');
//         }
//       }

//       return const PaymentResult(success: true, message: 'payment.success');
//     } catch (e, st) {
//       if (kDebugMode) {
//         print('Bazaar purchase error: $e\n$st');
//       }
//       return const PaymentResult(
//         success: false,
//         message: 'payment.process_error',
//       );
//     }
//   }
// }

// class DirectPaymentGateway implements PaymentGateway {
//   final PremiumServices _services;

//   DirectPaymentGateway(this._services);

//   @override
//   Future<PaymentResult> purchasePlan(PremiumPlanModel plan) async {
//     try {
//       final platform = kIsWeb
//           ? 'web'
//           : Platform.isIOS
//           ? 'ios'
//           : 'android';

//       final res = await _services.requestZarinpal(plan.id!, platform);

//       await ZarinpalPendingStore.saveLastHandledRefId(res.transaction);

//       final uri = Uri.parse(res.zarinpalUrl);
//       if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
//         throw Exception('Could not launch payment URL');
//       }

//       return const PaymentResult(success: false, pending: true);
//     } catch (e) {
//       await ZarinpalPendingStore.clear();
//       return PaymentResult(success: false, message: e.toString());
//     }
//   }
// }
