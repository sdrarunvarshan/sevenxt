// lib/screens/auth/views/password_recovery_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sevenxt/constants.dart';
import 'package:sevenxt/route/api_service.dart';
import 'package:sevenxt/route/route_constants.dart';
import 'package:sevenxt/screens/auth/views/components/otp_dialog.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isSendingOtp = false;
  bool _isResetting = false;
  bool _showPassword = false;

  // Step tracking: 1=Phone, 3=New Password (Step 2 is now handled by OtpDialog)
  int _currentStep = 1;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSendingOtp = true);

    try {
      final phone = _phoneController.text.trim();
      // Call backend to send OTP using the dedicated method
      final response = await ApiService.requestPasswordReset(phone);

      if (response['success'] == false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to send OTP'),
              backgroundColor: errorColor,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      // Show OTP dialog to verify the code
      print("✅ OTP sent successfully, showing dialog...");
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      String? otp = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => OtpDialog(
          phone: phone,
          onVerify: (otp) => ApiService.verifyPasswordResetOtp(phone, otp),
        ),
      );

      if (otp != null) {
        setState(() {
          _otpController.text = otp;
          _currentStep = 3; // Move to New Password step
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Phone verified successfully. Please set your new password.'),
              backgroundColor: successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isResetting = true);

    try {
      final response = await ApiService.resetPasswordWithOtp(
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        otp: _otpController.text.trim(),
        newPassword: _newPasswordController.text,
      );

      final authBox = Hive.box('auth');
      // Preserve has_seen_onboarding
      await authBox.delete('token');
      await authBox.delete('is_guest');
      await authBox.delete('user_email');
      await authBox.delete('user_phone');
      await authBox.delete('user_name');
      await authBox.delete('is_approved');
      ApiService.token = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successful. Please login again.'),
          backgroundColor: successColor,
        ),
      );

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          logInScreenRoute,
          (_) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  void _goBack() {
    if (_currentStep > 1) {
      setState(() => _currentStep = 1);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
          title: const Text('Reset Password'),
        ),
        body: SingleChildScrollView(
            child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420, // 👈 MOBILE FORM WIDTH (perfect for auth screens)
            ),
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: SvgPicture.asset(
                        "assets/logo/.svg",
                        height: 80,
                      ),
                    ),
                    const SizedBox(height: defaultPadding),
                    Text(
                      'Reset Password',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    const Text(
                      'Enter your registered phone number to reset password',
                    ),
                    const SizedBox(height: defaultPadding),

                    // Step Indicator
                    _buildStepIndicator(),
                    const SizedBox(height: defaultPadding),

                    // Step 1: Phone Input
                    if (_currentStep == 1) _buildPhoneStep(),

                    // Step 3: New Password (Step 2 OTP is now a dialog)
                    if (_currentStep == 3) _buildPasswordStep(),
                  ],
                ),
              ),
            ),
          ),
        )));
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStepCircle(1, 'Phone', _currentStep >= 1),
        Container(
          height: 2,
          width: 40,
          color: _currentStep >= 3 ? kPrimaryColor : blackColor20,
        ),
        _buildStepCircle(2, 'Verify', _currentStep >= 3),
        Container(
          height: 2,
          width: 40,
          color: _currentStep >= 3 ? kPrimaryColor : blackColor20,
        ),
        _buildStepCircle(3, 'Reset', _currentStep >= 3),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: active ? kPrimaryColor : blackColor20,
          child: Text(
            '$step',
            style: TextStyle(
              color: active ? Colors.white : blackColor60,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? kPrimaryColor : blackColor60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      children: [
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Phone number required';
            }
            if (!RegExp(r'^\+?[0-9]{10,13}$').hasMatch(value)) {
              return 'Enter valid phone number';
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Registered phone number',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: defaultPadding),
        const Text(
          'We will send a verification code to this number',
          style: TextStyle(color: blackColor40, fontSize: 12),
        ),
        const SizedBox(height: defaultPadding),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSendingOtp ? null : _sendOtp,
            child: _isSendingOtp
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Send Verification Code'),
          ),
        ),
        const SizedBox(height: defaultPadding),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to Login'),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        // Success indicator
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: successColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.verified, color: successColor),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Phone verified successfully',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: defaultPadding),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: emaildValidator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Registered email address',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: defaultPadding),
        // New Password
        TextFormField(
          controller: _newPasswordController,
          obscureText: !_showPassword,
          validator: passwordValidator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'New password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon:
                  Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: defaultPadding),

        // Confirm Password
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_showPassword,
          validator: passwordValidator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Confirm new password',
            prefixIcon: const Icon(Icons.lock_reset),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: defaultPadding),
        // Password requirements
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: blackColor5,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Password must have:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              SizedBox(height: 4),
              Text(
                '• At least 8 characters\n• Not too common\n• Not similar to phone number',
                style: TextStyle(fontSize: 11, color: blackColor40),
              ),
            ],
          ),
        ),
        const SizedBox(height: defaultPadding),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isResetting ? null : _resetPassword,
            child: _isResetting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Reset Password'),
          ),
        ),
      ],
    );
  }
}
