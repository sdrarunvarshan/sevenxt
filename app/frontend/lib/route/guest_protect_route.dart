// lib/widgets/guest_protected_route.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sevenext/route/guest_services.dart';
import 'package:sevenext/route/route_constants.dart';

class GuestProtectedRoute extends StatelessWidget {
  final Widget child;
  final String routeName;

  const GuestProtectedRoute({
    required this.child,
    required this.routeName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GuestService>(
      builder: (context, guestService, _) {
        if (guestService.isGuest && _isRestrictedRoute(routeName)) {
          return _buildAccessDeniedScreen(context);
        }
        return child;
      },
    );
  }

  bool _isRestrictedRoute(String route) {
    // Define routes guests cannot access
    final restrictedRoutes = [
      profileScreenRoute,
      ordersScreenRoute,
      discoverScreenRoute,
      cartScreenRoute,
      paymentScreenRoute,
      addressesScreenRoute,
      chatScreenRoute,
      userInfoScreenRoute,
      editUserInfoScreenRoute,

      // Add more restricted routes as needed
    ];
    return restrictedRoutes.contains(route);
  }

  Widget _buildAccessDeniedScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Access Denied")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "This feature is not available for guests",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  logInScreenRoute,
                      (route) => false,
                );
              },
              child: const Text("Sign In"),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  signUpScreenRoute,
                      (route) => false,
                );
              },
              child: const Text("Create Account"),
            ),
          ],
        ),
      ),
    );
  }
}