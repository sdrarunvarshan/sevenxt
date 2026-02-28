import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sevenxt/constants.dart';
import 'package:sevenxt/route/route_constants.dart';

import '../../../route/api_service.dart';
import '../../../route/guest_services.dart';
import '../../helpers/user_helper.dart';
import 'components/login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isB2CSelected = true;
  String? lockedUserType; // "b2c", "b2b", or null (first time)

  @override
  void initState() {
    super.initState();
    _loadSavedUserType();
  }

  Future<void> _loadSavedUserType() async {
    final box = Hive.box('auth');
    final savedType = box.get('user_type');

    if (savedType != null) {
      setState(() {
        lockedUserType = savedType.toString().toLowerCase();
        isB2CSelected = lockedUserType == "b2c";
      });
    }
  }

  void _onLoginSuccess(String userType) async {
    final authBox = Hive.box('auth');
    await UserHelper.setUserType(userType.toLowerCase()); // Already good
    bool isApproved = true; // Default for B2C
    if (userType.toLowerCase() == UserHelper.b2b) {
      try {
        final profile = await ApiService.getUserProfile();
        final status = profile['status']?.toString().toLowerCase() ?? 'pending';
        isApproved = status == 'approved';
        await authBox.put('is_approved', isApproved);
      } catch (e) {
        isApproved = false;
        await authBox.put('is_approved', false);
      }
    }
    setState(() {
      lockedUserType = userType.toLowerCase();
      isB2CSelected = userType == UserHelper.b2c;
    });
    // Navigate based on approval
    Navigator.pushReplacementNamed(
      context,
      isApproved ? entryPointScreenRoute : b2bApprovalPendingRoute,
    );
  }

  void _logoutAndReset() async {
    final authBox = Hive.box('auth');
    // Preserve has_seen_onboarding
    await authBox.delete('token');
    await authBox.delete('is_guest');
    await authBox.delete('user_email');
    await authBox.delete('user_phone');
    await authBox.delete('user_name');
    await authBox.delete('is_approved');
    await authBox.delete('user_type');
    await UserHelper.clearUserType(); // NEW: Clear user_type
    ApiService.token = null;
    setState(() {
      lockedUserType = null;
      isB2CSelected = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Logged out. You can now choose any login type.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Determine if tabs should be locked
    final bool isB2CLocked =
        lockedUserType == "b2b"; // B2C tab locked if user is B2B
    final bool isB2BLocked =
        lockedUserType == "b2c"; // B2B tab locked if user is B2C

    return Scaffold(
        appBar: AppBar(
          title: const Text("Login"),
          actions: lockedUserType != null
              ? [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: _logoutAndReset,
                    tooltip: "Logout to switch user type",
                  )
                ]
              : null,
        ),
        body: SingleChildScrollView(
            child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420, // 🔥 fixes web stretching
            ),
            child: Column(
              children: [
                // Capped height and contain fit to prevent giant images on Web
                SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height < 700 ? 140 : 200,
                  child: Image.asset(
                    "assets/images/login_dark.png",
                    fit: BoxFit.contain,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: SvgPicture.asset("assets/logo/sevenxt.svg",
                              height: 80)),
                      const SizedBox(height: defaultPadding / 2),

                      // Show message if user type is locked
                      if (lockedUserType != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: defaultPadding),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.amber.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "You are logged in as ${lockedUserType!.toUpperCase()} user. "
                                  "Tap logout icon to switch user type.",
                                  style:
                                      TextStyle(color: Colors.amber.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const Text("Log in with your registered account"),
                      const SizedBox(height: defaultPadding),

                      // Tabs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: !isB2CLocked
                                  ? () => setState(() => isB2CSelected = true)
                                  : null,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: isB2CSelected
                                      ? Theme.of(context).primaryColor
                                      : blackColor20,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      "B2C Login",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isB2CSelected
                                            ? Colors.white
                                            : blackColor60,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isB2CLocked)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          "(Not available)",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: errorColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: !isB2BLocked
                                  ? () => setState(() => isB2CSelected = false)
                                  : null,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: !isB2CSelected
                                      ? Theme.of(context).primaryColor
                                      : blackColor20,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      "B2B Login",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: !isB2CSelected
                                            ? Colors.white
                                            : blackColor60,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isB2BLocked)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          "(Not available)",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: errorColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Animated underline
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final tabWidth = (constraints.maxWidth - 16) / 2;

                          return Stack(
                            children: [
                              Container(height: 3, color: blackColor20),
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 300),
                                left: isB2CSelected ? 0 : tabWidth,
                                child: Container(
                                  width: tabWidth,
                                  height: 3,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: defaultPadding),

                      // Form
                      LogInForm(
                        formKey: _formKey,
                        isB2C: isB2CSelected,
                        onLoginSuccess: _onLoginSuccess,
                      ),

                      // Rest of UI...
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(
                              context, passwordRecoveryScreenRoute),
                          child: const Text("Forgot password?"),
                        ),
                      ),

                      SizedBox(height: defaultPadding / 2), // Reduced height,

                      OutlinedButton(
                        onPressed: () {
                          Provider.of<GuestService>(context, listen: false)
                              .setGuestMode(true);
                          Navigator.pushNamedAndRemoveUntil(
                              context, entryPointScreenRoute, (_) => false);
                        },
                        child: const Text("Continue as Guest"),
                      ),

                      const SizedBox(height: defaultPadding),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, signUpScreenRoute),
                            child: const Text("Sign up"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )));
  }
}
