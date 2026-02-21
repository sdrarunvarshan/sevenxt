import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:sevenxt/route/route_constants.dart';
import 'package:sevenxt/screens/helpers/user_helper.dart';

import '../../../route/api_service.dart';

class B2BApprovalPendingScreen extends StatelessWidget {
  const B2BApprovalPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Approval')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Your B2B account is pending approval.\nWe\'ll notify you once reviewed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  // Logout and go to login - preserve has_seen_onboarding
                  final authBox = Hive.box('auth');
                  await authBox.delete('token');
                  await authBox.delete('is_guest');
                  await authBox.delete('user_email');
                  await authBox.delete('user_phone');
                  await authBox.delete('user_name');
                  await authBox.delete('is_approved');
                  UserHelper.clearUserType();
                  ApiService.token = null;
                  Navigator.pushReplacementNamed(context, logInScreenRoute);
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}