import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sevenxt/models/cart_model.dart';
import 'package:sevenxt/route/api_service.dart';
import 'package:sevenxt/route/guest_services.dart';
import 'package:sevenxt/screens/auth/views/components/otp_dialog.dart';

import '../../../../constants.dart';
import '../../../../route/route_constants.dart';
import '../../../helpers/user_helper.dart';

class UserSignUpForm extends StatefulWidget {
  const UserSignUpForm({
    super.key,
    required this.formKey,
    required this.agreeToTerms,
  });

  final GlobalKey<FormState> formKey;
  final bool agreeToTerms;

  @override
  State<UserSignUpForm> createState() => _UserSignUpFormState();
}

class _UserSignUpFormState extends State<UserSignUpForm> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _countryController;

  bool _agreeToTerms = false;
  bool _showPassword = false;

  String? _requiredValidator(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  String? _pincodeValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Postal Code is required';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Enter valid 6-digit pincode';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _streetController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _postalCodeController = TextEditingController();
    _countryController = TextEditingController();
    _agreeToTerms = widget.agreeToTerms;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();

    super.dispose();
  }

  // In UserSignUpForm - update the _signUp method
  Future<void> _verifyAndSignUp() async {
    if (!widget.formKey.currentState!.validate()) return;

    final rawPhone = _phoneNumberController.text.trim();

    String phoneNumber;

    // 1️⃣ Validate & format phone number
    try {
      if (!ApiService.isValidPhoneNumber(rawPhone)) {
        throw Exception("Invalid phone number");
      }
      phoneNumber = ApiService.formatPhoneNumber(rawPhone);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter a valid Indian phone number")),
        );
      }
      return;
    }

    print("📱 Sending OTP for phone: $phoneNumber");

    // 2️⃣ Send OTP
    try {
      final otpResult = await ApiService.sendVerificationOtp(phoneNumber);

      // If the API returned a 2xx but has an error message in the body
      if (otpResult['success'] == false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(otpResult['message'] ?? "Failed to send OTP")),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send OTP: $e")),
        );
      }
      return;
    }

    // 3️⃣ Show OTP dialog and Verify
    print("✅ OTP sent successfully, showing dialog...");

    // Tiny delay to ensure UI is ready
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    String? otp;

    try {
      otp = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => OtpDialog(
          phone: phoneNumber,
          onVerify: (otp) => ApiService.verifyOtp(phoneNumber, otp),
        ),
      );
    } catch (e) {
      print("Error showing OTP dialog: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening verification dialog")),
        );
      }
      return;
    }

    print("Dialog closed with OTP: $otp");

    if (otp == null || otp.isEmpty) {
      print("❌ OTP verification cancelled or failed");
      return;
    }

    print("✅ OTP verified, proceeding with signup...");

    // 4️⃣ Proceed with signup
    await _signUp();
  }

  Future<void> _signUp() async {
    if (!widget.formKey.currentState!.validate()) return;

    final fullName = _fullNameController.text.trim();
    final phoneNumber = _phoneNumberController.text.trim();
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final postalCode = _postalCodeController.text.trim();
    final country = _countryController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final bool addressProvided = street.isNotEmpty &&
        city.isNotEmpty &&
        state.isNotEmpty &&
        postalCode.isNotEmpty &&
        country.isNotEmpty;

    // Create the request body for B2C signup
    final Map<String, dynamic> body = {
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'address': addressProvided
          ? {
              'address': street,
              'city': city,
              'state': state, // Added state
              'pincode': postalCode,
              'country': country,
              'name': 'Primary Address',
              'is_default': true,
            }
          : null,
    };

    try {
      // Send data to the backend API
      final response = await ApiService.post(
        '/auth/register/b2c',
        body: body,
      );

      if (!mounted) return;

      // Store token in ApiService and Hive
      final accessToken = response['access_token'] as String?;
      if (accessToken != null) {
        ApiService.token = accessToken;
        final authBox = Hive.box('auth');

        // IMPORTANT: Save token BEFORE making any other API calls
        await authBox.put('token', accessToken);
        await authBox.put('is_guest', false);

        // Save user data
        await authBox.put('user_name', fullName);
        await authBox.put('user_email', email);
        await authBox.put('user_phone', phoneNumber);

        print('✅ B2C Signup: Saved token and user data to Hive');
        print('  - Token: ${accessToken.substring(0, 20)}...');
        print('  - Name: $fullName');
        print('  - Email: $email');
        print('  - Phone: $phoneNumber');

        // Verify token is set in ApiService
        print(
            '✅ ApiService.token is now: ${ApiService.token?.substring(0, 20)}...');

        // Disable guest mode
        Provider.of<GuestService>(context, listen: false).setGuestMode(false);
        await UserHelper.setUserType(UserHelper.b2c);
        print('✅ B2C Signup: Set user type to B2C');
        // 🔥 LOAD USER-SCOPED CART (B2C)
        final cart = Cart();
        await cart.loadUserCart(email);

        print('🛒 Cart loaded for B2C user: $email');
      }

      // Handle success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Sign up successful!'),
        ),
      );

      // Navigate after all async work is done
      Navigator.pushNamedAndRemoveUntil(
          context, entryPointScreenRoute, (r) => false);
    } catch (e) {
      if (!mounted) return;

      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign Up Failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _fullNameController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.name,
            decoration: InputDecoration(
              hintText: 'Full Name',
              prefixIcon: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: defaultPadding * 0.75),
                child: SvgPicture.asset(
                  'assets/icons/Profile.svg',
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .color!
                        .withOpacity(0.3),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: defaultPadding),
          TextFormField(
            controller: _phoneNumberController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Phone Number',
              prefixIcon: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: defaultPadding * 0.75),
                child: SvgPicture.asset(
                  'assets/icons/Call.svg',
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .color!
                        .withOpacity(0.3),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: defaultPadding),
          const SizedBox(height: defaultPadding),
          TextFormField(
            controller: _streetController,
            validator: (v) => _requiredValidator(v, 'Street'),
            decoration: InputDecoration(
                hintText: 'Street',
                prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: defaultPadding * 0.75),
                    child: SvgPicture.asset(
                      'assets/icons/Address.svg',
                      height: 24,
                      width: 24,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .color!
                            .withOpacity(0.3),
                        BlendMode.srcIn,
                      ),
                    ))),
          ),
          const SizedBox(height: defaultPadding),
          TextFormField(
            controller: _cityController,
            validator: (v) => _requiredValidator(v, 'City'),
            decoration: InputDecoration(
                hintText: 'City',
                prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: defaultPadding * 0.75),
                    child: SvgPicture.asset(
                      'assets/icons/Address.svg',
                      height: 24,
                      width: 24,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .color!
                            .withOpacity(0.3),
                        BlendMode.srcIn,
                      ),
                    ))),
          ),
          const SizedBox(height: defaultPadding),
          TextFormField(
            controller: _stateController,
            validator: (v) => _requiredValidator(v, 'State'),
            decoration: InputDecoration(
                hintText: 'State',
                prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: defaultPadding * 0.75),
                    child: SvgPicture.asset(
                      'assets/icons/Address.svg',
                      height: 24,
                      width: 24,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .color!
                            .withOpacity(0.3),
                        BlendMode.srcIn,
                      ),
                    ))),
          ),
          const SizedBox(height: defaultPadding),
          TextFormField(
            controller: _postalCodeController,
            validator: _pincodeValidator,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Postal Code',
              prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: defaultPadding * 0.75),
                  child: SvgPicture.asset(
                    'assets/icons/Address.svg',
                    height: 24,
                    width: 24,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .color!
                          .withOpacity(0.3),
                      BlendMode.srcIn,
                    ),
                  )),
            ),
          ),
          const SizedBox(height: defaultPadding),
          TextFormField(
            controller: _countryController,
            validator: (v) => _requiredValidator(v, 'Country'),
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Country',
              prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: defaultPadding * 0.75),
                  child: SvgPicture.asset(
                    'assets/icons/Address.svg',
                    height: 24,
                    width: 24,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .color!
                          .withOpacity(0.3),
                      BlendMode.srcIn,
                    ),
                  )),
            ),
          ),
          const SizedBox(height: defaultPadding),
          TextFormField(
            controller: _emailController,
            validator: emaildValidator.call,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Email address',
              prefixIcon: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: defaultPadding * 0.75),
                child: SvgPicture.asset(
                  'assets/icons/Message.svg',
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .color!
                        .withOpacity(0.3),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: defaultPadding),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            validator: passwordValidator.call,
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: defaultPadding * 0.75),
                child: SvgPicture.asset(
                  'assets/icons/Lock.svg',
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .color!
                        .withOpacity(0.3),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                    _showPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
          const SizedBox(height: defaultPadding),
          Row(
            children: [
              Checkbox(
                activeColor: kPrimaryColor,
                onChanged: (value) {
                  setState(() {
                    _agreeToTerms = value!;
                  });
                },
                value: _agreeToTerms,
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: "I agree with the",
                    children: [
                      TextSpan(
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushNamed(
                                context, termsOfServicesScreenRoute);
                          },
                        text: " Terms of service ",
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: "& ",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium!.color,
                        ),
                      ),
                      TextSpan(
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(
                                  context, privacyPolicyScreenRoute);
                            },
                          text: " privacy policy.",
                          style: const TextStyle(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w500,
                          )),
                    ],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: defaultPadding),
          ElevatedButton(
            onPressed: _agreeToTerms ? _verifyAndSignUp : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              // Static Red Background
              foregroundColor: Colors.white,
              // Static White Text
              minimumSize: const Size(double.infinity, 50),
              // Explicitly set text color for disabled state to white to prevent grey color change
              disabledBackgroundColor: kPrimaryColor,
              disabledForegroundColor: Colors.white
                  .withOpacity(0.5), // Slightly faded white text when disabled
            ),
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }
}
