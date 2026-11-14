import 'package:flutter/material.dart';
import 'package:reservation_chat_univercity_project/features/appointments/service/model/appointment_models.dart';
import 'package:reservation_chat_univercity_project/features/home/services/model/home_models.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// Shared DRF list/paginated JSON parser.
List<T> parsePaginatedOrList<T>(
  dynamic json,
  T Function(Map<String, dynamic>) fromJson,
) {
  final List rawList;
  if (json is Map<String, dynamic> && json['results'] is List) {
    rawList = json['results'] as List;
  } else if (json is List) {
    rawList = json;
  } else {
    return <T>[];
  }

  return rawList
      .whereType<Map>()
      .map((item) => fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

/// Flattens hierarchical [CategoryModel] trees into a unique ordered list.
List<CategoryModel> flattenCategories(List<CategoryModel> roots) {
  final result = <CategoryModel>[];
  final seen = <String>{};

  void visit(CategoryModel node) {
    if (node.id.isNotEmpty && seen.add(node.id)) {
      result.add(node);
    }
    for (final child in node.children) {
      visit(child);
    }
  }

  for (final root in roots) {
    visit(root);
  }
  return result;
}

/// Minimal organization model returned by `GET organizations/my/`.
class MyOrganizationModel {
  final String id;
  final String name;
  final String slug;
  final bool isActive;

  const MyOrganizationModel({
    required this.id,
    required this.name,
    required this.slug,
    this.isActive = true,
  });

  factory MyOrganizationModel.fromJson(Map<String, dynamic> json) {
    return MyOrganizationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// Offering entity returned by `offerings/providers/<id>/` and `offerings/`.
class ProviderOfferingModel {
  final String id;
  final String organizationId;
  final String organizationName;
  final String providerId;
  final ProviderSpecialtyInlineModel? specialty;
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
  final String? createdAt;
  final String? updatedAt;

  const ProviderOfferingModel({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.providerId,
    this.specialty,
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
    this.createdAt,
    this.updatedAt,
  });

  factory ProviderOfferingModel.fromJson(Map<String, dynamic> json) {
    final orgRaw = json['organization'];
    final orgMap = orgRaw is Map
        ? Map<String, dynamic>.from(orgRaw)
        : const <String, dynamic>{};

    final providerRaw = json['provider'];
    final String parsedProviderId = providerRaw is Map
        ? (providerRaw['id']?.toString() ?? '')
        : (providerRaw?.toString() ?? '');

    final specialtyRaw = json['specialty'];
    final ProviderSpecialtyInlineModel? parsedSpecialty = specialtyRaw is Map
        ? ProviderSpecialtyInlineModel.fromJson(
            Map<String, dynamic>.from(specialtyRaw),
          )
        : null;

    return ProviderOfferingModel(
      id: json['id']?.toString() ?? '',
      organizationId: orgMap['id']?.toString() ?? '',
      organizationName: orgMap['name']?.toString() ?? '',
      providerId: parsedProviderId,
      specialty: parsedSpecialty,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      visitMode: VisitModeType.fromApi(json['visit_mode']?.toString()),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
      bufferBeforeMinutes:
          (json['buffer_before_minutes'] as num?)?.toInt() ?? 0,
      bufferAfterMinutes:
          (json['buffer_after_minutes'] as num?)?.toInt() ?? 0,
      priceValue: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      priceFormatted: formatTomanPrice(json['price']),
      requiresApproval: json['requires_approval'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  bool get isOnline => visitMode == VisitModeType.onlineChat;
  bool get isFree => priceValue <= 0;
  bool get hasBuffers => bufferBeforeMinutes > 0 || bufferAfterMinutes > 0;
  int get totalSlotMinutes =>
      durationMinutes + bufferBeforeMinutes + bufferAfterMinutes;

  String get visitModeLabel => isOnline ? 'مشاوره آنلاین' : 'ویزیت حضوری';

  String get priceLabel => isFree ? 'رایگان' : '$priceFormatted تومان';

  String get durationLabel =>
      '${toPersianDigits(durationMinutes.toString())} دقیقه';

  String get bufferSummaryText {
    if (!hasBuffers) return 'بدون زمان استراحت بین نوبت';
    final parts = <String>[];
    if (bufferBeforeMinutes > 0) {
      parts.add('${toPersianDigits(bufferBeforeMinutes.toString())} دقیقه قبل');
    }
    if (bufferAfterMinutes > 0) {
      parts.add('${toPersianDigits(bufferAfterMinutes.toString())} دقیقه بعد');
    }
    return 'آماده‌سازی: ${parts.join(' / ')}';
  }
}

/// Form payload for creating or updating an offering.
class OfferingFormPayload {
  final String title;
  final String description;
  final VisitModeType visitMode;
  final String? specialtyId;
  final int durationMinutes;
  final int bufferBeforeMinutes;
  final int bufferAfterMinutes;
  final int price;
  final bool requiresApproval;
  final bool isActive;

  const OfferingFormPayload({
    required this.title,
    this.description = '',
    required this.visitMode,
    this.specialtyId,
    required this.durationMinutes,
    this.bufferBeforeMinutes = 0,
    this.bufferAfterMinutes = 0,
    this.price = 0,
    this.requiresApproval = false,
    this.isActive = true,
  });

  Map<String, dynamic> toCreateJson({
    required String organizationId,
    required String providerId,
  }) {
    return {
      'organization_id': organizationId,
      'provider_id': providerId,
      ...toUpdateJson(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final normalizedSpecialtyId =
        (specialtyId != null && specialtyId!.trim().isNotEmpty)
        ? specialtyId!.trim()
        : null;
    return {
      'title': title.trim(),
      'description': description.trim(),
      'visit_mode': visitMode.apiValue,
      'specialty_id': normalizedSpecialtyId,
      'duration_minutes': durationMinutes,
      'buffer_before_minutes': bufferBeforeMinutes,
      'buffer_after_minutes': bufferAfterMinutes,
      'price': price,
      'requires_approval': requiresApproval,
      'is_active': isActive,
    };
  }
}

/// Ordered Persian weekdays matching backend `Weekday` integer choices
/// (`0 = Monday ... 5 = Saturday, 6 = Sunday`).
class PersianWeekdays {
  PersianWeekdays._();

  static const List<int> orderedCodes = [5, 6, 0, 1, 2, 3, 4];

  static const Map<int, String> names = {
    5: 'شنبه',
    6: 'یکشنبه',
    0: 'دوشنبه',
    1: 'سه‌شنبه',
    2: 'چهارشنبه',
    3: 'پنجشنبه',
    4: 'جمعه',
  };

  static String nameOf(int weekday) => names[weekday] ?? 'نامشخص';

  static int orderIndex(int weekday) {
    final index = orderedCodes.indexOf(weekday);
    return index == -1 ? 99 : index;
  }
}

/// Working hour shift model returned by `availability/providers/<id>/working-hours/`.
class WorkingHourModel {
  final String id;
  final String providerId;
  final int weekday;
  final String weekdayDisplay;
  final String startTime;
  final String endTime;
  final bool isActive;

  const WorkingHourModel({
    required this.id,
    required this.providerId,
    required this.weekday,
    required this.weekdayDisplay,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  factory WorkingHourModel.fromJson(Map<String, dynamic> json) {
    final providerRaw = json['provider'];
    final parsedProviderId = providerRaw is Map
        ? (providerRaw['id']?.toString() ?? '')
        : (providerRaw?.toString() ?? '');

    return WorkingHourModel(
      id: json['id']?.toString() ?? '',
      providerId: parsedProviderId,
      weekday: (json['weekday'] as num?)?.toInt() ?? 5,
      weekdayDisplay: json['weekday_display']?.toString() ?? '',
      startTime: _normalizeTimeString(json['start_time']?.toString() ?? ''),
      endTime: _normalizeTimeString(json['end_time']?.toString() ?? ''),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  TimeOfDay get startTimeOfDay => parseTimeOfDay(startTime);
  TimeOfDay get endTimeOfDay => parseTimeOfDay(endTime);

  int get startMinutes => timeOfDayToMinutes(startTimeOfDay);
  int get endMinutes => timeOfDayToMinutes(endTimeOfDay);
  int get durationMinutes => (endMinutes - startMinutes).clamp(0, 1440);

  String get persianWeekdayName => PersianWeekdays.nameOf(weekday);

  String get timeRangeLabel =>
      toPersianDigits('$startTime الی $endTime');

  String get durationLabel {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours > 0 && mins > 0) {
      return '${toPersianDigits(hours.toString())} ساعت و ${toPersianDigits(mins.toString())} دقیقه';
    }
    if (hours > 0) {
      return '${toPersianDigits(hours.toString())} ساعت';
    }
    return '${toPersianDigits(mins.toString())} دقیقه';
  }

  static String _normalizeTimeString(String raw) {
    final parts = raw.trim().split(':');
    if (parts.length < 2) return '09:00';
    final hh = parts[0].padLeft(2, '0');
    final mm = parts[1].padLeft(2, '0');
    return '$hh:$mm';
  }

  static TimeOfDay parseTimeOfDay(String raw) {
    final parts = raw.trim().split(':');
    final hour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 9) : 9;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return TimeOfDay(
      hour: hour.clamp(0, 23),
      minute: minute.clamp(0, 59),
    );
  }

  static String formatTimeOfDayApi(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static String formatTimeOfDayPersian(TimeOfDay time) =>
      toPersianDigits(formatTimeOfDayApi(time));

  static int timeOfDayToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  /// Checks whether a candidate time window overlaps any existing active shift.
  bool overlapsWith({
    required int candidateWeekday,
    required int candidateStartMinutes,
    required int candidateEndMinutes,
    String? excludingId,
  }) {
    if (!isActive) return false;
    if (excludingId != null && excludingId == id) return false;
    if (weekday != candidateWeekday) return false;
    return startMinutes < candidateEndMinutes && endMinutes > candidateStartMinutes;
  }

  /// Sorts shifts in Saturday..Friday order, then by start time ascending.
  static int compareForSchedule(WorkingHourModel a, WorkingHourModel b) {
    final dayCmp = PersianWeekdays.orderIndex(a.weekday)
        .compareTo(PersianWeekdays.orderIndex(b.weekday));
    if (dayCmp != 0) return dayCmp;
    return a.startMinutes.compareTo(b.startMinutes);
  }
}

/// Time-off block returned by `availability/providers/<id>/time-offs/`.
class TimeOffModel {
  final String id;
  final String providerId;
  final DateTime startAt;
  final DateTime endAt;
  final String reason;
  final bool isActive;

  const TimeOffModel({
    required this.id,
    required this.providerId,
    required this.startAt,
    required this.endAt,
    required this.reason,
    required this.isActive,
  });

  factory TimeOffModel.fromJson(Map<String, dynamic> json) {
    final providerRaw = json['provider'];
    final parsedProviderId = providerRaw is Map
        ? (providerRaw['id']?.toString() ?? '')
        : (providerRaw?.toString() ?? '');

    final parsedStart =
        DateTime.tryParse(json['start_at']?.toString() ?? '')?.toLocal() ??
        DateTime.now();
    final parsedEnd =
        DateTime.tryParse(json['end_at']?.toString() ?? '')?.toLocal() ??
        parsedStart.add(const Duration(hours: 1));

    return TimeOffModel(
      id: json['id']?.toString() ?? '',
      providerId: parsedProviderId,
      startAt: parsedStart,
      endAt: parsedEnd,
      reason: json['reason']?.toString() ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  bool get isEnded => DateTime.now().isAfter(endAt);

  bool get isOngoing {
    if (!isActive) return false;
    final now = DateTime.now();
    return !now.isBefore(startAt) && !now.isAfter(endAt);
  }

  bool get isUpcoming {
    if (!isActive) return false;
    return startAt.isAfter(DateTime.now());
  }

  bool get isSameDay =>
      startAt.year == endAt.year &&
      startAt.month == endAt.month &&
      startAt.day == endAt.day;

  String get jalaliRangeSummary {
    if (isSameDay) {
      return '${formatJalaliDate(startAt)} • ${formatClock(startAt)} الی ${formatClock(endAt)}';
    }
    return 'از ${formatJalaliDateTime(startAt)}\nتا ${formatJalaliDateTime(endAt)}';
  }

  static String formatJalaliDate(DateTime dt) {
    final local = dt.toLocal();
    final j = Jalali.fromDateTime(local);
    final f = j.formatter;
    return '${f.wN} ${toPersianDigits(j.day.toString())} ${f.mN} ${toPersianDigits(j.year.toString())}';
  }

  static String formatClock(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return toPersianDigits('$hh:$mm');
  }

  static String formatJalaliDateTime(DateTime dt) =>
      '${formatJalaliDate(dt)} • ${formatClock(dt)}';
}

