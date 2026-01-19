import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sevenext/constants.dart';
import 'package:sevenext/route/route_constants.dart';
import '../../../route/api_service.dart';
import '../../../route/guest_services.dart';
import 'components/login_form.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  void _onLoginSuccess(String userType) {
    setState(() {
      lockedUserType = userType.toLowerCase();
      isB2CSelected = userType == "b2c";
    });
  }

  void _logoutAndReset() async {
    final box = Hive.box('auth');
    await box.clear(); // Clear all saved auth data
    ApiService.token = null; // Clear API token

    setState(() {
      lockedUserType = null; // Reset locked type
      isB2CSelected = true; // Reset to B2C tab
    });

    // Show logout message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logged out. You can now choose any login type.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Determine if tabs should be locked
    final bool isB2CLocked = lockedUserType == "b2b"; // B2C tab locked if user is B2B
    final bool isB2BLocked = lockedUserType == "b2c"; // B2B tab locked if user is B2C

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
        child: Column(
          children: [
            Image.asset("assets/images/login_dark.png", fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: SvgPicture.asset("assets/logo/sevenextlon.svg", height: 80)),
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
                          Icon(Icons.info_outline, color: Colors.amber.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "You are logged in as ${lockedUserType!.toUpperCase()} user. "
                                  "Tap logout icon to switch user type.",
                              style: TextStyle(color: Colors.amber.shade900),
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isB2CSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "B2C Login",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isB2CSelected ? Colors.white : Colors.grey.shade700,
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
                                        color: Colors.red,
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: !isB2CSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "B2B Login",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !isB2CSelected ? Colors.white : Colors.grey.shade700,
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
                                        color: Colors.red,
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
                  Stack(
                    children: [
                      Container(height: 3, color: Colors.grey.shade300),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        left: isB2CSelected ? 0 : size.width / 2,
                        child: Container(
                          width: size.width / 2 - defaultPadding * 2,
                          height: 3,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
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
                      onPressed: () => Navigator.pushNamed(context, passwordRecoveryScreenRoute),
                      child: const Text("Forgot password?"),
                    ),
                  ),

                  SizedBox(height: size.height > 700 ? size.height * 0.1 : defaultPadding),

                  OutlinedButton(
                    onPressed: () {
                      Provider.of<GuestService>(context, listen: false).setGuestMode(true);
                      Navigator.pushNamedAndRemoveUntil(context, entryPointScreenRoute, (_) => false);
                    },
                    child: const Text("Continue as Guest"),
                  ),

                  const SizedBox(height: defaultPadding),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, signUpScreenRoute),
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
    );
  }
}