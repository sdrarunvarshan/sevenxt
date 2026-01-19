import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:sevenext/constants.dart';
import 'package:sevenext/route/guest_services.dart';
import 'package:sevenext/route/route_constants.dart';
import 'package:sevenext/screens/checkout/views/cart_screen.dart';
import 'package:sevenext/screens/discover/views/discover_screen.dart';import 'package:sevenext/screens/profile/views/profile_screen.dart';import 'package:sevenext/screens/address/views/addresses_screen.dart';import 'package:sevenext/screens/home/views/home_screen.dart';import 'package:sevenext/screens/onbording/views/onbording_screnn.dart';

class EntryPoint extends StatefulWidget {
  // Add an optional initial index parameter
  final int initialIndex;

  const EntryPoint({super.key, this.initialIndex = 0}); // Default to 0 (HomeScreen)

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  late int _currentIndex; // Use late initialization

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
    _currentIndex = widget.initialIndex;
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

        // Define restricted indices
        const int discoverIndex = 1;
        const int cartIndex = 2;
        const int profileIndex = 3;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: const SizedBox(),
            leadingWidth: 0,
            centerTitle: false,
            title: SvgPicture.asset(
              "assets/logo/Shoplon.svg",
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
                // Handle restricted tabs for guests
                if (isGuest && ( index == discoverIndex || index == cartIndex || index == profileIndex)) {
                  // Redirect guests to login
                  Navigator.pushNamed(context, logInScreenRoute);
                } else if (index == cartIndex) {
                  // For non-guests, navigate to CartScreen with showBackButton: false
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(showBackButton: false),
                    ),
                  );
                } else if (index != _currentIndex) {
                  // Update index for other tabs
                  setState(() {
                    _currentIndex = index;
                  });
                }
              },
              backgroundColor: Theme.of(context).brightness == Brightness.light
                  ? Colors.white
                  : const Color(0xFF101015),
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 12,
              selectedItemColor: kPrimaryColor,
              unselectedItemColor: Colors.transparent,
              items: [
                BottomNavigationBarItem(
                  icon: svgIcon("assets/icons/Shop.svg"),
                  activeIcon: svgIcon("assets/icons/Shop.svg", color: kPrimaryColor),
                  label: "Shop",
                ),
                BottomNavigationBarItem(
                  icon: svgIcon("assets/icons/Category.svg", color: isGuest ? Colors.grey : null),
                  activeIcon: svgIcon("assets/icons/Category.svg", color: kPrimaryColor),
                  label: "Discover",
                ),
                BottomNavigationBarItem(
                  icon: svgIcon("assets/icons/cart.svg", color: isGuest ? Colors.grey : null),
                  activeIcon: svgIcon("assets/icons/cart.svg", color: isGuest ? Colors.grey : kPrimaryColor),
                  label: "Cart",
                ),
                BottomNavigationBarItem(
                  icon: svgIcon("assets/icons/Profile.svg", color: isGuest ? Colors.grey : null),
                  activeIcon: svgIcon("assets/icons/Profile.svg", color: isGuest ? Colors.grey : kPrimaryColor),
                  label: "Profile",
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}