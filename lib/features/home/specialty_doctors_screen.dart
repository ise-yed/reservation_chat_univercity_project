import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/utils/search_box_widget.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_error_section.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_loading_section.dart';
import 'package:reservation_chat_univercity_project/core/widgets/pagination_error.dart';
import 'package:reservation_chat_univercity_project/core/widgets/pagination_indicator.dart';
import 'package:reservation_chat_univercity_project/core/widgets/reminders_appbar_widget.dart';
import 'package:reservation_chat_univercity_project/features/appointments/screens/doctor_profile_booking_screen.dart';
import 'package:reservation_chat_univercity_project/features/home/bloc/home_bloc.dart';
import 'package:reservation_chat_univercity_project/features/home/services/model/home_models.dart';

class SpecialtyDoctorsScreen extends StatefulWidget {
  final String? specialtyId;
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
  final PagingController<int, ProviderProfileModel> _pagingController =
      PagingController(firstPageKey: 1);

  late final HomeBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = HomeBloc();
    _pagingController.addPageRequestListener((pageKey) {
      _bloc.add(
        GetSpecialtyDoctorsEvent(
          page: pageKey,
          pageSize: _pageSize,
          specialtyId: widget.specialtyId,
          search: _searchController.text.trim(),
        ),
      );
    });
  }

  void _onSearchChanged(String value) {
    _pagingController.value = PagingState(
      nextPageKey: null,
      error: null,
      itemList: [],
    );
    _bloc.add(
      GetSpecialtyDoctorsEvent(
        page: 1,
        pageSize: _pageSize,
        specialtyId: widget.specialtyId,
        search: value.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pagingController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>.value(
      value: _bloc,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: BlocConsumer<HomeBloc, HomeState>(
              buildWhen: (previous, current) =>
                  current is SpecialtyDoctorsLoadingState ||
                  current is SpecialtyDoctorsSuccessState ||
                  current is SpecialtyDoctorsFailedState,
              listener: (context, state) {
                if (state is SpecialtyDoctorsSuccessState) {
                  final dataModel = state.providersResponse;
                  final newItems = dataModel.results;
                  final nextPageKey = dataModel.nextPage;

                  if (dataModel.page == 1) {
                    _pagingController.value = PagingState(
                      nextPageKey: nextPageKey,
                      error: null,
                      itemList: [],
                    );
                  }

                  if (nextPageKey == null) {
                    _pagingController.appendLastPage(newItems);
                  } else {
                    _pagingController.appendPage(newItems, nextPageKey);
                  }
                } else if (state is SpecialtyDoctorsFailedState) {
                  _pagingController.error = state.message;
                }
              },
              builder: (context, state) {
                final isFirstPage =
                    _pagingController.itemList == null ||
                    _pagingController.itemList!.isEmpty;

                return Column(
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
                      onChanged: _onSearchChanged,
                      onCloseTap: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      margin: EdgeInsets.only(
                        left: 24.w,
                        right: 24.w,
                        top: 12.h,
                        bottom: 12.h,
                      ),
                    ),
                    if (state is SpecialtyDoctorsLoadingState)
                      Expanded(child: GlobalLoadingSection())
                    else if (state is SpecialtyDoctorsFailedState &&
                        isFirstPage)
                      Expanded(
                        child: GlobalErrorSection(
                          message: state.message,
                          onRetry: () {
                            _bloc.add(
                              GetSpecialtyDoctorsEvent(
                                page: 1,
                                pageSize: _pageSize,
                                specialtyId: widget.specialtyId,
                                search: _searchController.text.trim(),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Expanded(
                        child: PagedListView<int, ProviderProfileModel>(
                          pagingController: _pagingController,
                          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                          builderDelegate:
                              PagedChildBuilderDelegate<ProviderProfileModel>(
                                itemBuilder: (context, doctor, index) =>
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 14.h),
                                      child: _DoctorCard(
                                        doctor: doctor,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  DoctorProfileBookingScreen(
                                                    providerId: doctor.id,
                                                    initialDoctorName:
                                                        doctor.displayName,
                                                    initialSpecialty:
                                                        doctor.specialtiesTitle,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                firstPageProgressIndicatorBuilder: (_) =>
                                    GlobalLoadingSection(),
                                firstPageErrorIndicatorBuilder: (_) =>
                                    GlobalErrorSection(
                                      message: _pagingController.error
                                          .toString()
                                          .replaceFirst('Exception: ', ''),
                                      onRetry: _pagingController
                                          .retryLastFailedRequest,
                                    ),
                                newPageProgressIndicatorBuilder: (_) =>
                                    GlobalPaginationLoadingSection(),
                                newPageErrorIndicatorBuilder: (_) =>
                                    GlobalPaginationErrorSection(
                                      message: _pagingController.error
                                          .toString()
                                          .replaceFirst('Exception: ', ''),
                                      onRetry: () {
                                        final failedPageKey =
                                            _pagingController.nextPageKey ?? 1;
                                        _bloc.add(
                                          GetSpecialtyDoctorsEvent(
                                            page: failedPageKey,
                                            pageSize: _pageSize,
                                            specialtyId: widget.specialtyId,
                                            search: _searchController.text
                                                .trim(),
                                          ),
                                        );
                                      },
                                    ),
                                noItemsFoundIndicatorBuilder: (_) => Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24.r),
                                    child: Text(
                                      'پزشکی برای این تخصص پیدا نشد.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                ),
                              ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final ProviderProfileModel doctor;
  final VoidCallback onTap;

  const _DoctorCard({required this.doctor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final String initial = doctor.user.fullName.trim().isNotEmpty
        ? doctor.user.fullName.trim().substring(0, 1)
        : 'پ';

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
              Container(
                width: 64.r,
                height: 64.r,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(14.r),
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
                    Text(
                      doctor.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineMedium?.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      doctor.specialtiesTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (doctor.organization.name.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            Icons.apartment_rounded,
                            size: 14.r,
                            color: AppColors.outline,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              doctor.clinicDisplayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'مشاهده پزشک',
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.primary500,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(
                          Icons.chevron_left_rounded,
                          size: 18.r,
                          color: AppColors.primary500,
                        ),
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
