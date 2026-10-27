import 'package:reservation_chat_univercity_project/features/home/services/model/home_models.dart';
import 'package:shamsi_date/shamsi_date.dart';

String toPersianDigits(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  String output = input;
  for (int i = 0; i < english.length; i++) {
    output = output.replaceAll(english[i], persian[i]);
  }
  return output;
}

String formatTomanPrice(dynamic rawPrice) {
  final doubleVal = double.tryParse(rawPrice?.toString() ?? '0') ?? 0;
  final intVal = doubleVal.round();
  final formatted = intVal.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
  return toPersianDigits(formatted);
}

enum VisitModeType {
  inPerson('in_person'),
  onlineChat('online_chat');

  final String apiValue;
  const VisitModeType(this.apiValue);

  static VisitModeType fromApi(String? value) {
    if (value == 'online_chat') return VisitModeType.onlineChat;
    return VisitModeType.inPerson;
  }
}

enum PaymentMethodType {
  online('online'),
  inPerson('in_person');

  final String apiValue;
  const PaymentMethodType(this.apiValue);

  static PaymentMethodType fromApi(String? value) {
    if (value == 'in_person') return PaymentMethodType.inPerson;
    return PaymentMethodType.online;
  }
}

enum PaymentStatusType {
  pending('pending'),
  paid('paid'),
  failed('failed'),
  cancelled('cancelled'),
  refunded('refunded');

  final String apiValue;
  const PaymentStatusType(this.apiValue);

  static PaymentStatusType fromApi(String? value) {
    switch (value) {
      case 'paid':
        return PaymentStatusType.paid;
      case 'failed':
        return PaymentStatusType.failed;
      case 'cancelled':
        return PaymentStatusType.cancelled;
      case 'refunded':
        return PaymentStatusType.refunded;
      default:
        return PaymentStatusType.pending;
    }
  }
}

enum AppointmentStatusType {
  pending('pending'),
  confirmed('confirmed'),
  completed('completed'),
  cancelledByCustomer('cancelled_by_customer'),
  cancelledByProvider('cancelled_by_provider'),
  noShow('no_show');

  final String value;
  const AppointmentStatusType(this.value);

  static AppointmentStatusType fromApi(String? value) {
    switch (value) {
      case 'pending':
        return AppointmentStatusType.pending;
      case 'confirmed':
        return AppointmentStatusType.confirmed;
      case 'completed':
        return AppointmentStatusType.completed;
      case 'cancelled_by_customer':
        return AppointmentStatusType.cancelledByCustomer;
      case 'cancelled_by_provider':
        return AppointmentStatusType.cancelledByProvider;
      case 'no_show':
        return AppointmentStatusType.noShow;
      default:
        return AppointmentStatusType.confirmed;
    }
  }
}

class OfferingModel {
  final String id;
  final String title;
  final String description;
  final VisitModeType visitMode;
  final int durationMinutes;
  final int bufferBeforeMinutes;
  final int bufferAfterMinutes;
  final double priceValue;
  final String priceFormatted;
  final bool requiresApproval;
  final bool isActive;

  OfferingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.visitMode,
    required this.durationMinutes,
    required this.bufferBeforeMinutes,
    required this.bufferAfterMinutes,
    required this.priceValue,
    required this.priceFormatted,
    required this.requiresApproval,
    required this.isActive,
  });

  factory OfferingModel.fromJson(Map<String, dynamic> json) {
    final mode = VisitModeType.fromApi(json['visit_mode']?.toString());
    final rawPrice = json['price'];
    final parsedPrice = double.tryParse(rawPrice?.toString() ?? '0') ?? 0.0;

    return OfferingModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      visitMode: mode,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      bufferBeforeMinutes:
          (json['buffer_before_minutes'] as num?)?.toInt() ?? 0,
      bufferAfterMinutes: (json['buffer_after_minutes'] as num?)?.toInt() ?? 0,
      priceValue: parsedPrice,
      priceFormatted: formatTomanPrice(rawPrice),
      requiresApproval: json['requires_approval'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  String get badgeText {
    if (visitMode == VisitModeType.onlineChat) {
      return 'چت و ویس پزشکی';
    }
    return requiresApproval ? 'نیازمند تأیید پزشک' : 'توصیه شده';
  }

  String get displaySubtitle {
    if (description.trim().isNotEmpty) return description.trim();
    if (visitMode == VisitModeType.onlineChat) {
      return 'گفت‌وگو در محیط چت و ارسال مدارک، عکس آزمایش و ویس';
    }
    return 'معاینه فیزیکی کامل و چکاپ علائم حیاتی در مطب';
  }
}

class AvailableSlotModel {
  final String providerId;
  final String offeringId;
  final String rawStartAt;
  final String rawEndAt;
  final DateTime startAt;
  final DateTime endAt;
  final int durationMinutes;
  final double priceValue;
  final String priceFormatted;

  AvailableSlotModel({
    required this.providerId,
    required this.offeringId,
    required this.rawStartAt,
    required this.rawEndAt,
    required this.startAt,
    required this.endAt,
    required this.durationMinutes,
    required this.priceValue,
    required this.priceFormatted,
  });

  factory AvailableSlotModel.fromJson(Map<String, dynamic> json) {
    final startStr = json['start_at']?.toString() ?? '';
    final endStr = json['end_at']?.toString() ?? '';
    final parsedStart =
        DateTime.tryParse(startStr)?.toLocal() ?? DateTime.now();
    final parsedEnd = DateTime.tryParse(endStr)?.toLocal() ?? parsedStart;

    return AvailableSlotModel(
      providerId: json['provider_id']?.toString() ?? '',
      offeringId: json['offering_id']?.toString() ?? '',
      rawStartAt: startStr,
      rawEndAt: endStr,
      startAt: parsedStart,
      endAt: parsedEnd,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      priceValue: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      priceFormatted: formatTomanPrice(json['price']),
    );
  }

  bool get isFuture => startAt.isAfter(DateTime.now());

  String get timeLabel {
    final hh = startAt.hour.toString().padLeft(2, '0');
    final mm = startAt.minute.toString().padLeft(2, '0');
    return toPersianDigits('$hh:$mm');
  }
}

class AvailableSlotsResponse {
  final String date;
  final int count;
  final List<AvailableSlotModel> results;

  AvailableSlotsResponse({
    required this.date,
    required this.count,
    required this.results,
  });

  factory AvailableSlotsResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['results'] is List
        ? json['results'] as List
        : const [];
    final allSlots = rawList
        .map((x) => AvailableSlotModel.fromJson(Map<String, dynamic>.from(x)))
        .where((slot) => slot.isFuture)
        .toList();

    return AvailableSlotsResponse(
      date: json['date']?.toString() ?? '',
      count: allSlots.length,
      results: allSlots,
    );
  }
}

class PaymentModel {
  final String id;
  final String appointmentId;
  final double amount;
  final String amountFormatted;
  final PaymentMethodType method;
  final PaymentStatusType status;
  final String? paidAt;
  final String? createdAt;
  final String? payUrl;

  PaymentModel({
    required this.id,
    required this.appointmentId,
    required this.amount,
    required this.amountFormatted,
    required this.method,
    required this.status,
    this.paidAt,
    this.createdAt,
    this.payUrl,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id']?.toString() ?? '',
      appointmentId: json['appointment']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      amountFormatted: formatTomanPrice(json['amount']),
      method: PaymentMethodType.fromApi(json['method']?.toString()),
      status: PaymentStatusType.fromApi(json['status']?.toString()),
      paidAt: json['paid_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      payUrl: json['pay_url']?.toString(),
    );
  }
}

class AppointmentModel {
  final String id;
  final ProviderOrganizationInlineModel organization;
  final ProviderBranchInlineModel? branch;
  final ProviderUserInlineModel customer;
  final ProviderProfileModel provider;
  final OfferingModel offering;
  final VisitModeType visitMode;
  final String rawStartAt;
  final String rawEndAt;
  final DateTime startAt;
  final DateTime endAt;
  final AppointmentStatusType status;
  final double priceValue;
  final String priceFormatted;
  final PaymentModel? payment;
  final String notes;
  final String cancelReason;
  final String? cancelledAt;
  final String? payUrl;

  AppointmentModel({
    required this.id,
    required this.organization,
    this.branch,
    required this.customer,
    required this.provider,
    required this.offering,
    required this.visitMode,
    required this.rawStartAt,
    required this.rawEndAt,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.priceValue,
    required this.priceFormatted,
    this.payment,
    required this.notes,
    required this.cancelReason,
    this.cancelledAt,
    this.payUrl,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final sStr = json['start_at']?.toString() ?? '';
    final eStr = json['end_at']?.toString() ?? '';
    final parsedStart = DateTime.tryParse(sStr)?.toLocal() ?? DateTime.now();
    final parsedEnd = DateTime.tryParse(eStr)?.toLocal() ?? parsedStart;

    return AppointmentModel(
      id: json['id']?.toString() ?? '',
      organization: ProviderOrganizationInlineModel.fromJson(
        json['organization'] is Map
            ? Map<String, dynamic>.from(json['organization'])
            : <String, dynamic>{},
      ),
      branch: json['branch'] is Map
          ? ProviderBranchInlineModel.fromJson(
              Map<String, dynamic>.from(json['branch']),
            )
          : null,
      customer: ProviderUserInlineModel.fromJson(
        json['customer'] is Map
            ? Map<String, dynamic>.from(json['customer'])
            : <String, dynamic>{},
      ),
      provider: ProviderProfileModel.fromJson(
        json['provider'] is Map
            ? Map<String, dynamic>.from(json['provider'])
            : <String, dynamic>{},
      ),
      offering: OfferingModel.fromJson(
        json['offering'] is Map
            ? Map<String, dynamic>.from(json['offering'])
            : <String, dynamic>{},
      ),
      visitMode: VisitModeType.fromApi(json['visit_mode']?.toString()),
      rawStartAt: sStr,
      rawEndAt: eStr,
      startAt: parsedStart,
      endAt: parsedEnd,
      status: AppointmentStatusType.fromApi(json['status']?.toString()),
      priceValue: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      priceFormatted: '${formatTomanPrice(json['price'])} تومان',
      payment: json['payment'] is Map
          ? PaymentModel.fromJson(Map<String, dynamic>.from(json['payment']))
          : null,
      notes: json['notes']?.toString() ?? '',
      cancelReason: json['cancel_reason']?.toString() ?? '',
      cancelledAt: json['cancelled_at']?.toString(),
      payUrl: json['pay_url']?.toString(),
    );
  }

  String get shortId {
    if (id.length <= 8) return id.toUpperCase();
    return id.substring(0, 8).toUpperCase();
  }

  bool get hasStarted =>
      DateTime.now().isAfter(startAt) ||
      DateTime.now().isAtSameMomentAs(startAt);

  bool get isCurrentlyInProgress {
    final now = DateTime.now();
    return (now.isAfter(startAt) || now.isAtSameMomentAs(startAt)) &&
        now.isBefore(endAt);
  }

  String get jalaliDateText {
    final jalali = Jalali.fromDateTime(startAt);
    final f = jalali.formatter;
    final now = DateTime.now();
    final isToday =
        now.year == startAt.year &&
        now.month == startAt.month &&
        now.day == startAt.day;
    final prefix = isToday ? 'امروز، ' : '${f.wN}، ';
    return '$prefix${toPersianDigits(jalali.day.toString())} ${f.mN} ${toPersianDigits(jalali.year.toString())}';
  }

  String get timeRangeText {
    final sH = startAt.hour.toString().padLeft(2, '0');
    final sM = startAt.minute.toString().padLeft(2, '0');
    final eH = endAt.hour.toString().padLeft(2, '0');
    final eM = endAt.minute.toString().padLeft(2, '0');
    return toPersianDigits('$sH:$sM الی $eH:$eM');
  }

  String? get clinicAddress {
    if (branch != null && branch!.address.trim().isNotEmpty) {
      return '${organization.name} - ${branch!.address}';
    }
    if (organization.name.trim().isNotEmpty) {
      return organization.name;
    }
    return null;
  }
}

class PaginatedAppointmentsResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<AppointmentModel> results;
  final int page;

  PaginatedAppointmentsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
    required this.page,
  });

  bool get hasNextPage => next != null && next!.isNotEmpty;
  int? get nextPage => hasNextPage ? page + 1 : null;

  factory PaginatedAppointmentsResponse.fromJson(
    dynamic json, {
    required int currentPage,
  }) {
    if (json is Map<String, dynamic>) {
      final list = json['results'] is List
          ? List<AppointmentModel>.from(
              (json['results'] as List).map(
                (x) => AppointmentModel.fromJson(Map<String, dynamic>.from(x)),
              ),
            )
          : <AppointmentModel>[];
      return PaginatedAppointmentsResponse(
        count: (json['count'] as num?)?.toInt() ?? list.length,
        next: json['next']?.toString(),
        previous: json['previous']?.toString(),
        results: list,
        page: currentPage,
      );
    }
    if (json is List) {
      final list = List<AppointmentModel>.from(
        json.map(
          (x) => AppointmentModel.fromJson(Map<String, dynamic>.from(x)),
        ),
      );
      return PaginatedAppointmentsResponse(
        count: list.length,
        results: list,
        page: currentPage,
      );
    }
    return PaginatedAppointmentsResponse(
      count: 0,
      results: const [],
      page: currentPage,
    );
  }
}
