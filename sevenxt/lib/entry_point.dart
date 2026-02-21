import 'dart:async'; // NEW: For Timer

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sevenxt/constants.dart';
import 'package:sevenxt/route/api_service.dart';
import 'package:sevenxt/route/guest_services.dart';
import 'package:sevenxt/route/route_constants.dart';
import 'package:sevenxt/screens/checkout/views/cart_screen.dart';
import 'package:sevenxt/screens/discover/views/discover_screen.dart';
import 'package:sevenxt/screens/home/views/home_screen.dart';
import 'package:sevenxt/screens/profile/views/profile_screen.dart';

import '/screens/helpers/user_helper.dart';

class EntryPoint extends StatefulWidget {
  // Add an optional initial index parameter
  final int initialIndex;

  const EntryPoint(
      {super.key, this.initialIndex = 0}); // Default to 0 (HomeScreen)

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  late int _currentIndex; // Use late initialization
  Timer? _approvalTimer;

  final List<Widget> _pages = const [
    HomeScreen(),
    DiscoverScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize _currentIndex with the value from the widget's constructor
    final savedIndex = Hive.box('user_settings')
        .get('last_tab_index', defaultValue: widget.initialIndex);
    _currentIndex = savedIndex;
    _startApprovalPolling();
  }

  void _startApprovalPolling() async {
    final userType = await UserHelper.getUserType();
    if (userType != UserHelper.b2b) return; // Only for B2B

    _approvalTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      final isApproved = await _checkApproval();

      // Ensure we are still in the tree and not in the middle of a build
      if (!mounted) return;

      if (isApproved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your B2B account has been approved!')),
        );
        timer.cancel(); // Stop polling once approved
      } else {
        // Use Future.delayed to ensure navigation happens after any current build cycle
        Future.delayed(Duration.zero, () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, b2bApprovalPendingRoute);
            timer.cancel();
          }
        });
      }
    });
  }

  Future<bool> _checkApproval() async {
    final authBox = Hive.box('auth');
    try {
      final profile = await ApiService.getUserProfile();
      final status = profile['status']?.toString().toLowerCase() ?? 'pending';
      final isApproved = status == 'approved';
      await authBox.put('is_approved', isApproved);
      return isApproved;
    } catch (e) {
      return authBox.get('is_approved', defaultValue: false);
    }
  }

  @override
  void dispose() {
    _approvalTimer?.cancel(); // Clean up timer
    super.dispose();
  }

  // Helper function for SVG icons
  SvgPicture svgIcon(String src, {Color? color}) {
    return SvgPicture.asset(
      src,
      height: 24,
      colorFilter: ColorFilter.mode(
        color ??
            Theme.of(context).iconTheme.color!.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.3 : 1,
                ),
        BlendMode.srcIn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GuestService>(
      builder: (context, guestService, child) {
        final bool isGuest = guestService.isGuest;

        const int discoverIndex = 1;
        const int cartIndex = 2;
        const int profileIndex = 3;

        // PopScope handles the back button behavior
        return PopScope(
          canPop: _currentIndex == 0, // Allow exit only if on Home tab
          onPopInvoked: (didPop) {
            if (didPop) return;
            // If not on Home tab, switch to Home tab
            setState(() {
              _currentIndex = 0;
            });
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              leading: const SizedBox(),
              leadingWidth: 0,
              centerTitle: false,
              title: SvgPicture.asset(
                "assets/logo/sevenxt.svg",
                height: 85,
                width: 120,
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, searchScreenRoute);
                  },
                  icon: SvgPicture.asset(
                    "assets/icons/Search.svg",
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).textTheme.bodyLarge!.color!,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, notificationScreenRoute);
                      // Handle notification tap
                    },
                    icon: SvgPicture.asset(
                      "assets/icons/notification.svg",
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).textTheme.bodyLarge!.color!,
                        BlendMode.srcIn,
                      ),
                    ))
              ],
            ),
            body: PageTransitionSwitcher(
              duration: defaultDuration,
              transitionBuilder: (child, animation, secondAnimation) {
                return FadeThroughTransition(
                  animation: animation,
                  secondaryAnimation: secondAnimation,
                  child: child,
                );
              },
              child: _pages[_currentIndex],
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.only(top: defaultPadding / 2),
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.white
                  : const Color(0xFF101015),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  if (isGuest &&
                      (index == discoverIndex ||
                          index == cartIndex ||
                          index == profileIndex)) {
                    Navigator.pushNamed(context, logInScreenRoute);
                  } else if (index == cartIndex) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const CartScreen(showBackButton: false),
                      ),
                    );
                  } else if (index != _currentIndex) {
                    setState(() {
                      _currentIndex = index;
                    });
                    Hive.box('user_settings')
                        .put('last_tab_index', _currentIndex);
                  }
                },
                backgroundColor:
                    Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : const Color(0xFF101015),
                type: BottomNavigationBarType.fixed,
                selectedFontSize: 12,
                selectedItemColor: kPrimaryColor,
                unselectedItemColor: Colors.transparent,
                items: [
                  BottomNavigationBarItem(
                    icon: svgIcon("assets/icons/Shop.svg"),
                    activeIcon:
                        svgIcon("assets/icons/Shop.svg", color: kPrimaryColor),
                    label: "Shop",
                  ),
                  BottomNavigationBarItem(
                    icon: svgIcon("assets/icons/Category.svg",
                        color: isGuest ? Colors.grey : null),
                    activeIcon: svgIcon("assets/icons/Category.svg",
                        color: kPrimaryColor),
                    label: "Discover",
                  ),
                  BottomNavigationBarItem(
                    icon: svgIcon("assets/icons/cart.svg",
                        color: isGuest ? Colors.grey : null),
                    activeIcon: svgIcon("assets/icons/cart.svg",
                        color: isGuest ? Colors.grey : kPrimaryColor),
                    label: "Cart",
                  ),
                  BottomNavigationBarItem(
                    icon: svgIcon("assets/icons/Profile.svg",
                        color: isGuest ? Colors.grey : null),
                    activeIcon: svgIcon("assets/icons/Profile.svg",
                        color: isGuest ? Colors.grey : kPrimaryColor),
                    label: "Profile",
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
