import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reservation_chat_univercity_project/core/constants/app_setting.dart';
import 'package:reservation_chat_univercity_project/features/home/home.dart';
import 'package:reservation_chat_univercity_project/features/profile/screens/profile_screen.dart';
import 'package:reservation_chat_univercity_project/features/root/placeholder_screens.dart';

import 'dart:ui' as ui;

// Role constants — match Django UserRoles choices.
const _kRoleProvider = 'provider';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

ValueNotifier<int> currentIndex = ValueNotifier(0);

class _RootScreenState extends State<RootScreen> {
  static List<Widget> _screensFor(String role) {
    if (role == _kRoleProvider) {
      return const [
        ProviderDashboardScreen(),
        ChatsScreen(),
        MyServicesScreen(),
        ProfileScreen(),
      ];
    }
    return const [
      HomeScreen(),
      MyAppointmentsScreen(),
      ChatsScreen(),
      ProfileScreen(),
    ];
  }

  static List<_NavItem> _itemsFor(String role) {
    if (role == _kRoleProvider) {
      return const [
        _NavItem(label: 'nav.dashboard',   icon: 'stethoscope'),
        _NavItem(label: 'nav.inbox',       icon: 'chat',            hasBadge: true),
        _NavItem(label: 'nav.my_services', icon: 'medical_service'),
        _NavItem(label: 'nav.profile',     icon: 'user-circle'),
      ];
    }
    return const [
      _NavItem(label: 'nav.home',         icon: 'home'),
      _NavItem(label: 'nav.appointments', icon: 'calendar'),
      _NavItem(label: 'nav.chats',        icon: 'chat',  hasBadge: true),
      _NavItem(label: 'nav.profile',      icon: 'user-circle'),
    ];
  }

  late String _role;
  late List<Widget> _screens;
  late List<_NavItem> _items;

  @override
  void initState() {
    super.initState();
    _role    = currentUserModel.role ?? '';
    _screens = _screensFor(_role);
    _items   = _itemsFor(_role);
    currentIndex.value = 0;
  }

  void _onTap(int i) {
    if (currentIndex.value == i) return;
    HapticFeedback.selectionClick();
    currentIndex.value = i;
  }

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;
    final navH  = 88.h;

    return PopScope(
      canPop: currentIndex.value == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && currentIndex.value != 0) {
          currentIndex.value = 0;
        }
      },
      child: Scaffold(
        extendBody: true,
        body: ValueListenableBuilder<int>(
          valueListenable: currentIndex,
          builder: (context, value, _) {
            return Stack(
              children: [
                IndexedStack(index: value, children: _screens),
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      height: navH,
                      decoration: BoxDecoration(color: cs.shadow),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Row(
                          textDirection: isRtl
                              ? ui.TextDirection.rtl
                              : ui.TextDirection.ltr,
                          children: List.generate(_items.length, (i) {
                            return _NavButton(
                              item:     _items[i],
                              selected: value == i,
                              onTap:    () => _onTap(i),
                            );
                          }),
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
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final primary  = cs.primary;
    final inactive = cs.tertiary;
    final iconSize = Size(24.w, 24.h);

    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve:    Curves.easeOut,
              height:   2,
              margin:   EdgeInsets.symmetric(horizontal: 6.w),
              decoration: BoxDecoration(
                color: selected ? primary : Colors.transparent,
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap:          onTap,
                splashColor:    Colors.transparent,
                highlightColor: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 30.h,
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/${item.icon}.svg',
                          width:  iconSize.width,
                          height: iconSize.height,
                          colorFilter: ColorFilter.mode(
                            selected ? primary : inactive,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      item.label.tr(),
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: selected ? primary : inactive),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final String icon;
  final bool hasBadge;

  const _NavItem({
    required this.label,
    required this.icon,
    this.hasBadge = false,
  });
}
