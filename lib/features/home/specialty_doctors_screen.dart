import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/widgets/app_cached_image.dart';
import 'package:reservation_chat_univercity_project/core/widgets/reminders_appbar_widget.dart';
import 'package:reservation_chat_univercity_project/core/utils/search_box_widget.dart';
import 'package:reservation_chat_univercity_project/features/appointments/screens/doctor_profile_booking_screen.dart';

/// صفحه فهرست پزشکان یک تخصص.
/// فعلاً داده‌ها از نمونه‌های HomeScreen می‌آیند؛ بعداً می‌توان منبع را به API وصل کرد.
class SpecialtyDoctorsScreen extends StatefulWidget {
  final String specialtyId;
  final String specialtyTitle;

  const SpecialtyDoctorsScreen({
    super.key,
    required this.specialtyId,
    required this.specialtyTitle,
  });

  @override
  State<SpecialtyDoctorsScreen> createState() => _SpecialtyDoctorsScreenState();
}

class _SpecialtyDoctorsScreenState extends State<SpecialtyDoctorsScreen> {
  static const int _pageSize = 10;

  final TextEditingController _searchController = TextEditingController();
  final PagingController<int, _DoctorItem> _pagingController =
      PagingController(firstPageKey: 1);

  late final List<_DoctorItem> _allDoctors;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _allDoctors = _sampleDoctors
        .where((doctor) => doctor.specialtyIds.contains(widget.specialtyId))
        .toList();

    _pagingController.addPageRequestListener(_fetchPage);
  }

  void _fetchPage(int pageKey) {
    // شبیه‌سازی صفحه‌بندی برای داده‌های نمونه؛ در اتصال به API این قسمت جایگزین شود.
    final query = _query.trim().toLowerCase();
    final filtered = _allDoctors.where((doctor) {
      return query.isEmpty ||
          doctor.name.toLowerCase().contains(query) ||
          doctor.specialty.toLowerCase().contains(query) ||
          doctor.medicalCode.toLowerCase().contains(query);
    }).toList();

    final start = (pageKey - 1) * _pageSize;
    if (start >= filtered.length) {
      _pagingController.appendLastPage(const []);
      return;
    }

    final end = (start + _pageSize).clamp(0, filtered.length);
    final items = filtered.sublist(start, end);
    if (end >= filtered.length) {
      _pagingController.appendLastPage(items);
    } else {
      _pagingController.appendPage(items, pageKey + 1);
    }
  }

  void _search(String value) {
    _query = value;
    _pagingController.refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              RemindersAppbarWidget(
                title: widget.specialtyTitle,
                leadingIcon: IconButton(
                  tooltip: 'بازگشت',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              SearchBoxWidget(
                controller: _searchController,
                backColor: Theme.of(context).colorScheme.shadow,
                haveFilter: false,
                onChanged: _search,
                onCloseTap: () {
                  _searchController.clear();
                  _search('');
                },
                margin: EdgeInsets.only(
                  left: 24.w,
                  right: 24.w,
                  top: 12.h,
                  bottom: 12.h,
                ),
              ),
              Expanded(
                child: PagedListView<int, _DoctorItem>(
                  pagingController: _pagingController,
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                  builderDelegate: PagedChildBuilderDelegate<_DoctorItem>(
                    itemBuilder: (context, doctor, index) => Padding(
                      padding: EdgeInsets.only(bottom: 14.h),
                      child: _DoctorCard(
                        doctor: doctor,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DoctorProfileBookingScreen(
                                providerId: doctor.id,
                                initialDoctorName: doctor.name,
                                initialSpecialty: doctor.specialty,
                                initialAvatarUrl: doctor.avatarUrl,
                                initialMedicalCode: doctor.medicalCode,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    firstPageProgressIndicatorBuilder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                    newPageProgressIndicatorBuilder: (_) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    firstPageErrorIndicatorBuilder: (_) => Center(
                      child: TextButton(
                        onPressed: _pagingController.retryLastFailedRequest,
                        child: const Text('تلاش مجدد'),
                      ),
                    ),
                    newPageErrorIndicatorBuilder: (_) => Center(
                      child: TextButton(
                        onPressed: _pagingController.retryLastFailedRequest,
                        child: const Text('بارگذاری مجدد'),
                      ),
                    ),
                    noItemsFoundIndicatorBuilder: (_) => Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.r),
                        child: Text(
                          'پزشکی برای این تخصص پیدا نشد.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final _DoctorItem doctor;
  final VoidCallback onTap;

  const _DoctorCard({required this.doctor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.text200Light),
            boxShadow: [
              BoxShadow(
                color: AppColors.text700Light.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14.r),
                    child: AppCachedImage(
                      url: doctor.avatarUrl,
                      width: 64.r,
                      height: 64.r,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: -3.r,
                    right: -3.r,
                    child: Container(
                      width: 14.r,
                      height: 14.r,
                      decoration: BoxDecoration(
                        color: doctor.isOnline
                            ? AppColors.primary500
                            : AppColors.outline,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surfaceContainerLowest,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineMedium?.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      doctor.specialty,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 4.h,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                size: 15.r, color: AppColors.tertiaryContainer),
                            SizedBox(width: 3.w),
                            Text(doctor.rating,
                                style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700)),
                            SizedBox(width: 3.w),
                            Text('(${doctor.reviewsCount} نظر)',
                                style: textTheme.titleSmall?.copyWith(
                                    color: AppColors.outline)),
                          ],
                        ),
                        Text(
                          'کد نظام پزشکی: ${doctor.medicalCode}',
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          doctor.isOnline
                              ? Icons.circle
                              : Icons.circle_outlined,
                          size: 9.r,
                          color: doctor.isOnline
                              ? AppColors.primary500
                              : AppColors.outline,
                        ),
                        SizedBox(width: 5.w),
                        Expanded(
                          child: Text(
                            doctor.isOnline ? 'آنلاین' : 'آفلاین',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          'مشاهده پزشک',
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.primary500,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(Icons.chevron_left_rounded,
                            size: 18.r, color: AppColors.primary500),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorItem {
  final String id;
  final String name;
  final String specialty;
  final String avatarUrl;
  final String rating;
  final String reviewsCount;
  final String medicalCode;
  final bool isOnline;
  final List<String> specialtyIds;

  const _DoctorItem({
    required this.id,
    required this.name,
    required this.specialty,
    required this.avatarUrl,
    required this.rating,
    required this.reviewsCount,
    required this.medicalCode,
    required this.isOnline,
    required this.specialtyIds,
  });
}

// داده‌های نمونه هماهنگ با پزشکان فعلی HomeScreen.
// هر پزشک فقط در تخصص‌های متناظر نمایش داده می‌شود.
const List<_DoctorItem> _sampleDoctors = [
  _DoctorItem(
    id: '1',
    name: 'دکتر مریم صادقی',
    specialty: 'فوق تخصص قلب و عروق و اکوکاردیوگرافی',
    avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBaivf4mRYB_mgxeKxpoOOrc2R_Wk09Q7d7n3YI1Ll_WelviZmaPUJJ-7BpiBi_Ixm7871l_H431z8JNBmooMS2cp0cA33GLN_JD78CpwObNocuvwgWXiWFgvNRSJjgusUp8dmVkoHb9XUPgWWnxihNZXeFaIxzauFslyUCYgKfwLaHerFuOWImiwm5Z-DP7M4JquvW_26jca29dq-If1bDjcI2DIjQaJI6WiTgihTj4krm2CMG5rKg',
    rating: '۴.۹',
    reviewsCount: '۱۴۲',
    medicalCode: '۸۴۳۲۰',
    isOnline: true,
    specialtyIds: ['cardiology'],
  ),
  _DoctorItem(
    id: '2',
    name: 'دکتر آرش فرهمند',
    specialty: 'متخصص و بورد تخصصی پوست، مو و زیبایی',
    avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCI7U8dX2Y_-S4H228kNjlcmjokA3khvAHTU8f4hW470sJXxAKPiS2-d2a8FhudhulpYeRBjxBldlncAvsjC2LBhbBLfAi7ou1UEWgExLZpw09eT_d4rFEs7fnGhiYMcP3Ve-9_SebotabOYHVb7QQw0S9zQomr2rxq1CvUmY021nrpDGfS5bHxEEEZnH-ky9-S_e3UmqKZuYXKBVh3wvMwqM2ngLO6AKGa_02AAd8o54sl3KtdEJZK',
    rating: '۴.۸',
    reviewsCount: '۹۸',
    medicalCode: '۹۲۱۰۴',
    isOnline: true,
    specialtyIds: ['dermatology'],
  ),
  _DoctorItem(
    id: '3',
    name: 'دکتر سارا کاظمی',
    specialty: 'متخصص کودکان، نوزادان و رشد کودک',
    avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAmfSbvwOXnsB1HefvPPcSmZTzalZ6NEzSxtQjWvuqwtG9hE8pjG9u6iz1j4HsyvVzQvek94mssz5FYXbX58H3iC-yFKMnLbz31deeq0sbaWgPCYciSBa77nrK1rjuspgGO94MN5zi4tbDXCwGDvey1UKsV1Am7_2XRmCFrHDevKLvr4B_rI2umkOC3tgRi42OQtGddkBAUvMFsumQ2XFeOU8qNB3TcxDAiLLEWJ1aaby4yHhm_RtL3',
    rating: '۴.۹',
    reviewsCount: '۲۱۵',
    medicalCode: '۶۷۵۱۸',
    isOnline: true,
    specialtyIds: ['pediatrics'],
  ),
  _DoctorItem(
    id: '4',
    name: 'دکتر کامران بهرامی',
    specialty: 'جراح مغز و اعصاب و ستون فقرات',
    avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC6g_DP3Hc4rYCpkgIwsJo4ZLTulhLFC5EYTzIN4OqPh3WWJncwdkNSenz-ZBvOkj_91gU_gYNgXkIuDo5v2zhtHUV_aZgOeKFHb7Yq3YgYNBqs_IfvvL3eXxTkNDrGxUnl4I0tc8LWoOzEbp0s-lHwl3cLvL599ArIgoGhVrAph7JTbM5AR2Ka6MmCfR5oiI8N44Ag5KEpjAXtWEXIgkTZ4nbIwijXt25ZZ8N1F0qh1RjbwB70q1-8',
    rating: '۴.۷',
    reviewsCount: '۷۶',
    medicalCode: '۵۱۲۰۴',
    isOnline: false,
    specialtyIds: ['neurology', 'orthopedics'],
  ),
];
