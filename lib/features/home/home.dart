import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_setting.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/utils/navigator.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_error_section.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_loading_section.dart';
import 'package:reservation_chat_univercity_project/features/appointments/screens/doctor_profile_booking_screen.dart';
import 'package:reservation_chat_univercity_project/features/home/bloc/home_bloc.dart';
import 'package:reservation_chat_univercity_project/features/home/services/model/home_models.dart';
import 'package:reservation_chat_univercity_project/features/home/specialty_doctors_screen.dart';
import 'package:reservation_chat_univercity_project/features/profile/screens/notification_screen.dart';
import 'package:reservation_chat_univercity_project/features/profile/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final HomeBloc _homeBloc;
  final Set<String> _bookmarkedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _homeBloc = HomeBloc()..add(GetHomeDataEvent(pageSize: 10));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _homeBloc.close();
    super.dispose();
  }

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    String output = input;
    for (int i = 0; i < english.length; i++) {
      output = output.replaceAll(english[i], persian[i]);
    }
    return output;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>.value(
      value: _homeBloc,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              _buildTopHeader(context),
              Expanded(
                child: BlocBuilder<HomeBloc, HomeState>(
                  buildWhen: (previous, current) =>
                      current is HomeDataLoadingState ||
                      current is HomeDataSuccessState ||
                      current is HomeDataFailedState,
                  builder: (context, state) {
                    if (state is HomeDataLoadingState || state is HomeInitial) {
                      return GlobalLoadingSection();
                    }

                    if (state is HomeDataFailedState) {
                      return GlobalErrorSection(
                        message: state.message,
                        onRetry: () {
                          _homeBloc.add(GetHomeDataEvent(pageSize: 10));
                        },
                      );
                    }

                    if (state is HomeDataSuccessState) {
                      final categories = state.categories;
                      final providers = state.providersResponse.results;
                      final totalProvidersCount = state.providersResponse.count;

                      return RefreshIndicator(
                        onRefresh: () async {
                          _homeBloc.add(GetHomeDataEvent(pageSize: 10));
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: EdgeInsets.only(bottom: 96.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSpecialtiesSection(context, categories),
                              _buildUrgentConsultationBanner(context),
                              _buildDoctorsListSection(
                                context,
                                providers: providers,
                                totalCount: totalProvidersCount,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ۱. هدر بالای صفحه (Header)
  // ---------------------------------------------------------------------------
  Widget _buildTopHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final String userName =
        (currentUserModel.fullName != null &&
            currentUserModel.fullName!.trim().isNotEmpty)
        ? currentUserModel.fullName!.trim()
        : ((currentUserModel.firstName != null &&
                  currentUserModel.firstName!.trim().isNotEmpty)
              ? '${currentUserModel.firstName ?? ''} ${currentUserModel.lastName ?? ''}'
                    .trim()
              : 'کاربر گرامی');

    final String userInitial = userName.isNotEmpty
        ? userName.substring(0, 1)
        : 'ک';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: AppColors.text700Light.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 34.r,
                      height: 34.r,
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.local_hospital_rounded,
                        color: AppColors.primary500,
                        size: 22.r,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'درمانیار',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.headlineMedium?.copyWith(
                                    color: AppColors.primary500,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  'Home',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontSize: 10.sp,
                                    color: AppColors.outline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14.r,
                                color: AppColors.primary500,
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Text(
                                  'روزبخیر، $userName',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.outline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(50.r),
                    onTap: () {
                      goScreen(context: context, screen: NotificationScreen());
                    },
                    child: SizedBox(
                      width: 42.r,
                      height: 42.r,
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 24.r,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  GestureDetector(
                    onTap: () {
                      goScreen(context: context, screen: const ProfileScreen());
                    },
                    child: Container(
                      width: 34.r,
                      height: 34.r,
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary500.withOpacity(0.25),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        userInitial,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.primary500,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ۲. بخش دسته‌بندی تخصص‌ها (Grid 4 ستونه متصل به GET /api/v1/categories/)
  // ---------------------------------------------------------------------------
  Widget _buildSpecialtiesSection(
    BuildContext context,
    List<CategoryModel> categories,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6.w,
                      height: 18.h,
                      decoration: BoxDecoration(
                        color: AppColors.primary500,
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'دسته‌بندی تخصص‌ها',
                      style: textTheme.headlineMedium?.copyWith(
                        fontSize: 16.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8.r),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SpecialtyDoctorsScreen(
                          specialtyId: "",
                          specialtyTitle: 'همه پزشکان و متخصصان',
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 4.h,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'مشاهده همه',
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.primary500,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Icon(
                          Icons.arrow_back_rounded,
                          size: 14.r,
                          color: AppColors.primary500,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          if (categories.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Text(
                'دسته‌بندی تخصصی ثبت نشده است.',
                style: textTheme.bodySmall?.copyWith(color: AppColors.outline),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                  childAspectRatio: 0.88,
                ),
                itemBuilder: (context, index) {
                  final item = categories[index];
                  final bool usePrimary = index.isEven;
                  final Color accentColor = usePrimary
                      ? AppColors.primary500
                      : AppColors.secondary;

                  return Material(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16.r),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16.r),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SpecialtyDoctorsScreen(
                              specialtyId: item.id,
                              specialtyTitle: item.name,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: AppColors.surfaceContainerLow,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.text700Light.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 46.r,
                              height: 46.r,
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                item.resolvedIcon,
                                size: 26.r,
                                color: accentColor,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: textTheme.labelMedium?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ۳. بنر گرادینت مشاوره فوری پزشکی متنی و تلفنی
  // ---------------------------------------------------------------------------
  Widget _buildUrgentConsultationBanner(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              AppColors.primary500,
              AppColors.primary400,
              AppColors.secondary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary300.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: -24.r,
              bottom: -24.r,
              child: IgnorePointer(
                child: Container(
                  width: 112.r,
                  height: 112.r,
                  decoration: BoxDecoration(
                    color: AppColors.text700Dark.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.text700Dark.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(50.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FadeTransition(
                                opacity: Tween<double>(
                                  begin: 0.35,
                                  end: 1.0,
                                ).animate(_pulseController),
                                child: Container(
                                  width: 6.r,
                                  height: 6.r,
                                  decoration: const BoxDecoration(
                                    color: AppColors.secondaryFixed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'پاسخگویی سریع ۲۴ ساعته',
                                style: textTheme.titleSmall?.copyWith(
                                  color: AppColors.text700Dark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'مشاوره فوری پزشکی متنی و صوتی',
                          style: textTheme.headlineMedium?.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text700Dark,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'ارتباط مستقیم با برترین پزشکان شیفت بدون نیاز به معطلی در مطب',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.surfaceContainerHigh,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      color: AppColors.text700Dark.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.bolt_rounded,
                      color: AppColors.text700Dark,
                      size: 26.r,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ۴. لیست پزشکان برتر و متخصصان در دسترس (متصل به GET /api/v1/providers/)
  // ---------------------------------------------------------------------------
  Widget _buildDoctorsListSection(
    BuildContext context, {
    required List<ProviderProfileModel> providers,
    required int totalCount,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 16.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6.w,
                    height: 18.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary500,
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'پزشکان برتر و متخصصان در دسترس',
                    style: textTheme.headlineMedium?.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                '${_toPersianDigits(totalCount.toString())} متخصص فعال',
                style: textTheme.titleSmall?.copyWith(color: AppColors.outline),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (providers.isEmpty)
            Container(
              padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.text200Light),
              ),
              alignment: Alignment.center,
              child: Text(
                'در حال حاضر پزشک فعالی یافت نشد.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: providers.length,
              separatorBuilder: (_, __) => SizedBox(height: 14.h),
              itemBuilder: (context, index) {
                final provider = providers[index];
                return _buildDoctorCard(context, provider);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, ProviderProfileModel doc) {
    final textTheme = Theme.of(context).textTheme;
    final bool isBookmarked = _bookmarkedIds.contains(doc.id);
    final String initial = doc.user.fullName.trim().isNotEmpty
        ? doc.user.fullName.trim().substring(0, 1)
        : 'پ';

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.text200Light, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.text700Light.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ردیف بالا: آواتار، نام، تخصص، کلینیک و دکمه نشان کردن (بدون امتیاز، کد نظام پزشکی و نقطه آنلاین)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64.r,
                height: 64.r,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: textTheme.headlineMedium?.copyWith(
                    fontSize: 22.sp,
                    color: AppColors.primary500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.headlineMedium?.copyWith(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                doc.specialtiesTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(8.r),
                          onTap: () {
                            setState(() {
                              if (isBookmarked) {
                                _bookmarkedIds.remove(doc.id);
                              } else {
                                _bookmarkedIds.add(doc.id);
                              }
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.all(4.r),
                            child: Icon(
                              isBookmarked
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              size: 20.r,
                              color: isBookmarked
                                  ? AppColors.tertiary
                                  : AppColors.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (doc.organization.name.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            Icons.apartment_rounded,
                            size: 14.r,
                            color: AppColors.primary500,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              doc.clinicDisplayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall?.copyWith(
                                color: AppColors.outline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // ردیف پایین: مدت زمان پیش‌فرض ویزیت و دکمه دریافت نوبت
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 16.r,
                      color: AppColors.primary500,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        'مدت زمان پایه ویزیت: ${_toPersianDigits(doc.defaultSlotDurationMinutes.toString())} دقیقه',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Material(
                color: AppColors.primary500,
                borderRadius: BorderRadius.circular(12.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: () {
                    goScreen(
                      context: context,
                      screen: DoctorProfileBookingScreen(
                        providerId: doc.id,
                        initialDoctorName: doc.displayName,
                        initialSpecialty: doc.specialtiesTitle,
                      ),
                    );
                  },
                  child: Container(
                    height: 40.h,
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'دریافت نوبت',
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.text700Dark,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.chevron_left_rounded,
                          size: 18.r,
                          color: AppColors.text700Dark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
