import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sevenxt/route/api_service.dart';
import 'package:sevenxt/route/route_constants.dart';

import '../screens/helpers/user_helper.dart';

class AuthWrapper extends StatelessWidget {
  final Widget child;
  const AuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkApproval(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final isApproved = snapshot.data ?? true;
        if (!isApproved) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, b2bApprovalPendingRoute);
          });
          return const SizedBox.shrink();
        }
        return child;
      },
    );
  }

  Future<bool> _checkApproval() async {
    final authBox = Hive.box('auth');
    final userType = await UserHelper.getUserType();
    if (userType != UserHelper.b2b) return true;

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
}