import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sevenxt/components/list_tile/divider_list_tile.dart';
import 'package:sevenxt/constants.dart';
import 'package:sevenxt/models/cart_model.dart'; // Import Cart
import 'package:sevenxt/route/screen_export.dart';

import '../../../components/skleton/skelton.dart';
import '../../../route/api_service.dart';
import '../../helpers/user_helper.dart';
import 'components/profile_card.dart';
import 'components/profile_menu_item_list_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = "Guest";
  String _email = "Sign in to unlock features";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final authBox = Hive.box('auth');

    final isGuest = authBox.get('is_guest');
    final token = authBox.get('token');

    String tempName;
    String tempEmail;

    // Guest or no token → show default
    if (isGuest == true || token == null) {
      tempName = "Guest";
      tempEmail = "Sign in to unlock features";

      // Only update if changed
      if (_name != tempName || _email != tempEmail) {
        setState(() {
          _name = tempName;
          _email = tempEmail;
        });
      }
      return;
    }

    // USER LOGGED IN → Call backend
    try {
      final profile = await ApiService.getUserProfile();

      tempName = profile["full_name"] ?? "User";
      tempEmail = profile["email"] ?? "";

      // Save for future use
      authBox.put("user_name", tempName);
      authBox.put("user_email", tempEmail);

      // Update state only if changed
      if (_name != tempName || _email != tempEmail) {
        setState(() {
          _name = tempName;
          _email = tempEmail;
        });
      }
    } catch (e) {
      print("Failed to load profile: $e");

      // On error fallback to stored data
      final storedName = authBox.get('user_name', defaultValue: "User");
      final storedEmail = authBox.get('user_email', defaultValue: "");

      if (_name != storedName || _email != storedEmail) {
        setState(() {
          _name = storedName;
          _email = storedEmail;
        });
      }
    }
  }

  // Helper function to get initials from a name
  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    } else if (nameParts.length >= 2) {
      return (nameParts[0].substring(0, 1) + nameParts[1].substring(0, 1))
          .toUpperCase();
    } else {
      return ""; // Should not happen for valid names
    }
  }

  Future<void> _handlePaymentNavigation() async {
    final authBox = Hive.box('auth');
    final isGuest = authBox.get('is_guest');

    if (isGuest == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please login to access payment features")),
      );
      return;
    }

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircleSkeleton(size: 40)),
    );

    try {
      final userType = await UserHelper.getUserType();

      if (userType == UserHelper.b2b) {
        final profile = await ApiService.getUserProfile();
        final status = profile['status']?.toString().toLowerCase();

        if (status != 'approved') {
          if (mounted) Navigator.pop(context); // Remove loader

          String message = "Your B2B account is ";
          if (status == 'pending') {
            message += "pending approval.";
          } else if (status == 'rejected') {
            message += "rejected.";
          } else if (status == 'suspended') {
            message += "suspended.";
          } else {
            message += "not approved.";
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          }
          return;
        }
      }

      if (mounted) {
        Navigator.pop(context); // Remove loader
        Navigator.pushNamed(context, paymentScreenRoute);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Remove loader
      print("Error checking payment access: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Could not verify account status. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 1200, // Prevent it from stretching too much on web
      ),
      child: ListView(
        children: [
          ProfileCard(
            name: _name,
            email: _email,
            // Use CircleAvatar to display initials
            profileImageWidget: CircleAvatar(
              radius: 30, // Adjust radius as needed
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                _getInitials(_name),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            press: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UserInfoScreen()));
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            child: Text(
              "Account",
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: defaultPadding / 2),
          DividerListTile(
            leading: SvgPicture.asset(
              "assets/icons/Order.svg",
              height: 24,
              width: 24,
              colorFilter: ColorFilter.mode(
                Theme.of(context).iconTheme.color!,
                BlendMode.srcIn,
              ),
            ),
            title:
                const Text("Orders", style: TextStyle(fontSize: 14, height: 1)),
            press: () => Navigator.pushNamed(context, ordersScreenRoute),
          ),
          ProfileMenuListTile(
            text: "Addresses",
            svgSrc: "assets/icons/Address.svg",
            press: () => Navigator.pushNamed(context, addressesScreenRoute),
          ),

          DividerListTile(
            leading: SvgPicture.asset(
              "assets/icons/card.svg",
              height: 24,
              width: 24,
              colorFilter: ColorFilter.mode(
                Theme.of(context).iconTheme.color!,
                BlendMode.srcIn,
              ),
            ),
            title: const Text("Payment",
                style: TextStyle(fontSize: 14, height: 1)),
            isShowDivider: false, // last item in Account
            press: () => Navigator.pushNamed(
              context,
              paymentScreenRoute,
            ),
          ),
          const SizedBox(height: defaultPadding),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding, vertical: defaultPadding / 2),
            child: Text(
              "Help & Support",
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ProfileMenuListTile(
            text: "Get Help",
            svgSrc: "assets/icons/Help.svg",
            press: () {
              Navigator.pushNamed(context, getHelpScreenRoute);
            },
          ),
          ProfileMenuListTile(
            text: "About us",
            svgSrc: "assets/icons/Danger Circle.svg",
            press: () {
              Navigator.pushNamed(context, aboutUsScreenRoute);
            },
          ),
          ProfileMenuListTile(
            text: "Terms of Service",
            svgSrc: "assets/icons/Standard.svg",
            press: () {
              Navigator.pushNamed(context, termsOfServicesScreenRoute);
            },
          ),

          ProfileMenuListTile(
            text: "Privacy Policy",
            svgSrc: "assets/icons/Standard.svg",
            press: () {
              Navigator.pushNamed(context, privacyPolicyScreenRoute);
            },
          ),
          ProfileMenuListTile(
            text: "Return & Refund Policy",
            svgSrc: "assets/icons/Standard.svg",
            press: () {
              Navigator.pushNamed(context, ReturnRefundPolicyScreenRoute);
            },
          ),
          ProfileMenuListTile(
            text: "Grievance Redressal Policy",
            svgSrc: "assets/icons/Help.svg",
            press: () {
              Navigator.pushNamed(context, grievanceRedressalScreenRoute);
            },
          ),
          ProfileMenuListTile(
            text: "Contact us",
            svgSrc: "assets/icons/Help.svg",
            press: () {
              Navigator.pushNamed(context, contactUsScreenRoute);
            },
          ),
          const SizedBox(height: defaultPadding),

          // Log Out
          ListTile(
            onTap: () async {
              final authBox = Hive.box('auth');
              await authBox.delete('token');
              await authBox.delete('is_approved');
              await authBox.put('is_guest', true); // Reset to guest
              await UserHelper.clearUserType(); // NEW
              ApiService.token = null;
              Cart().clearCart();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            minLeadingWidth: 24,
            leading: SvgPicture.asset(
              "assets/icons/Logout.svg",
              height: 24,
              width: 24,
              colorFilter: const ColorFilter.mode(
                errorColor,
                BlendMode.srcIn,
              ),
            ),
            title: const Text(
              "Log Out",
              style: TextStyle(color: errorColor, fontSize: 14, height: 1),
            ),
          )
        ],
      ),
    )));
  }
}
