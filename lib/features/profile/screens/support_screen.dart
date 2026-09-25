import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:reservation_chat_univercity_project/core/themes/app_colors.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_error_section.dart';
import 'package:reservation_chat_univercity_project/core/widgets/global_loading_section.dart';
import 'package:reservation_chat_univercity_project/core/widgets/main_button.dart';
import 'package:reservation_chat_univercity_project/core/widgets/main_textfield.dart';
import 'package:reservation_chat_univercity_project/features/profile/bloc/profile_bloc.dart';
import 'package:reservation_chat_univercity_project/features/profile/widgets/support/support_list_item_widget.dart';
// import 'package:reservation_chat_univercity_project/features/reminder/widgets/home/floationg_Button.dart';
import 'package:reservation_chat_univercity_project/core/widgets/reminders_appbar_widget.dart';
import 'package:flutter/widgets.dart' as ui;

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  @override
  initState() {
    super.initState();

    BlocProvider.of<ProfileBloc>(context).add(GetTicketListEvent());
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController subjectController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bool isRTL = Directionality.of(context) == ui.TextDirection.rtl;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ElevatedButton(
                //   onPressed: () {
                //     BlocProvider.of<ProfileBloc>(
                //       context,
                //     ).add(GetTicketListEvent());
                //   },
                //   child: Text("data"),
                // ),
                RemindersAppbarWidget(
                  title: "support".tr(),
                  leadingIcon: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: RotatedBox(
                      quarterTurns: isRTL ? 0 : 2,
                      child: SvgPicture.asset(
                        "assets/icons/arrow-right.svg",
                        width: 24.w,
                        height: 24.h,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.onSurface,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),

                BlocBuilder<ProfileBloc, ProfileState>(
                  buildWhen: (previous, current) =>
                      current is GetTicketListSuccessState ||
                      current is GetTicketListErrorState ||
                      current is GetTicketListLoadingState,
                  builder: (context, state) {
                    if (state is GetTicketListLoadingState) {
                      return Expanded(child: GlobalLoadingSection());
                    } else if (state is GetTicketListErrorState) {
                      return Expanded(
                        child: GlobalErrorSection(
                          message: state.message,
                          onRetry: () {
                            BlocProvider.of<ProfileBloc>(context)
                                .add(GetTicketListEvent());
                          },
                        ),
                      );
                    } else if (state is GetTicketListSuccessState) {
                      if (state.tickets == null || state.tickets!.isEmpty) {
                        return Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: 47.h),

                              SvgPicture.asset(
                                "assets/icons/headphones.svg",
                                height: 72.h,
                                width: 72.w,

                                colorFilter: ColorFilter.mode(
                                  Theme.of(context).colorScheme.onTertiary,
                                  BlendMode.srcIn,
                                ),
                              ),

                              SizedBox(height: 46.h),

                              Text(
                                "empty_support_title".tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                              SizedBox(height: 15.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 18.w),
                                child: Text(
                                  "empty_support_des".tr(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium!
                                      .copyWith(height: 1.5.h),
                                ),
                              ),
                              SizedBox(height: 46.h),
                              SizedBox(
                                width: 234.w,
                                child: CustomElevatedButton(
                                  onTap: () {
                                    AddTicketBottomSheetWidget(context);
                                  },
                                  text: "add_ticket".tr(),
                                  icon: SizedBox(
                                    height: 24.h,
                                    width: 24.w,

                                    child: SvgPicture.asset(
                                      "assets/icons/plus.svg",

                                      colorFilter: ColorFilter.mode(
                                        AppColors.text700Dark,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  iconSpace: 4.w,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 14.h),
                            child: ListView.builder(
                              padding: EdgeInsets.only(bottom: 100.h),
                              shrinkWrap: true,
                              itemCount: state.tickets!.length,
                              itemBuilder: (context, index) {
                                return SupportListItemWidget(
                                  ticketModel: state.tickets![index],
                                );
                              },
                            ),
                          ),
                        );
                      }
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),

            // AddSomthingFloatingActionButtonWidget(
            //   onTap: () {
            //     AddTicketBottomSheetWidget(context);
            //   },
            // ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> AddTicketBottomSheetWidget(BuildContext context) {
    return showModalBottomSheet(
      isDismissible: false,
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
            ),
            padding: EdgeInsets.only(bottom: 23.h, right: 24.w, left: 24.w),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RemindersAppbarWidget(
                      horizontalPadding: 0,
                      title: "add_support_ticket".tr(),
                      trailingIcon: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.pop(context),
                        child: SvgPicture.asset(
                          "assets/icons/remove.svg",
                          width: 24.w,
                          height: 24.h,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).colorScheme.onSurface,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 19.h),

                    Text(
                      "ticket_subject".tr(),
                      style: Theme.of(context).textTheme.titleMedium!
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 9.h),
                    CoreTextField(
                      controller: subjectController,
                      hint: "ticket_subject".tr(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "fill_subject_fields".tr();
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 17.h),

                    Text(
                      "description".tr(),
                      style: Theme.of(context).textTheme.titleMedium!
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 9.h),
                    CoreTextField(
                      controller: descriptionController,
                      hint: "description_hint".tr(),
                      textFieldHeight: 144,
                      maxLines: 6,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "fill_des_fields".tr();
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 25.h),

                    BlocConsumer<ProfileBloc, ProfileState>(
                      buildWhen: (previous, current) =>
                          current is CreateTicketSuccessState ||
                          current is CreateTicketErrorState ||
                          current is CreateTicketLoadingState,
                      listenWhen: (previous, current) =>
                          current is CreateTicketSuccessState ||
                          current is CreateTicketErrorState ||
                          current is CreateTicketLoadingState,
                      listener: (context, state) {
                        if (state is CreateTicketSuccessState) {
                          subjectController.clear();
                          descriptionController.clear();
                          BlocProvider.of<ProfileBloc>(context)
                              .add(GetTicketListEvent());
                          Navigator.pop(context);
                        }
                      },
                      builder: (context, state) {
                        return CustomElevatedButton(
                          loading: state is CreateTicketLoadingState,
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              BlocProvider.of<ProfileBloc>(context).add(
                                CreateTicketEvent(
                                  subject: subjectController.text.trim(),
                                  description: descriptionController.text
                                      .trim(),
                                  message: descriptionController.text.trim(),
                                ),
                              );
                            }
                          },
                          text: 'add'.tr(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
