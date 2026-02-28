import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sevenxt/models/cart_model.dart';
import 'package:sevenxt/route/api_service.dart';
import 'package:sevenxt/route/guest_services.dart';
import 'package:sevenxt/screens/auth/views/components/otp_dialog.dart';

import '../../../../constants.dart';
import '../../../../route/route_constants.dart';
import '../../../helpers/user_helper.dart';

class B2BSignUpForm extends StatefulWidget {
  const B2BSignUpForm({
    super.key,
    required this.formKey,
  });

  final GlobalKey<FormState> formKey;

  @override
  State<B2BSignUpForm> createState() => _B2BSignUpState();
}

class _B2BSignUpState extends State<B2BSignUpForm> {
  late final TextEditingController _businessNameController;
  late final TextEditingController _gstinController;
  late final TextEditingController _panController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController
      _addressController; // Renamed from _streetController
  late final TextEditingController _cityController;
  late final TextEditingController _stateController; // Added state controller
  late final TextEditingController _postalCodeController;
  late final TextEditingController _countryController;

  bool _phoneVerified = false;
  String? _verificationOtp;
  bool _isSendingOtp = false;
  final TextEditingController _otpController = TextEditingController();

  String? gstCertificateFileName;
  String? businessLicenseFileName;
  PlatformFile? gstCertificateFile;
  PlatformFile? businessLicenseFile;
  bool _agreeToTerms = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _gstinController = TextEditingController();
    _panController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _addressController = TextEditingController(); // Initialize new controller
    _cityController = TextEditingController();
    _stateController = TextEditingController(); // Initialize state controller
    _postalCodeController = TextEditingController();
    _countryController = TextEditingController();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose(); // Dispose new controller
    _cityController.dispose();
    _stateController.dispose(); // Dispose state controller
    _postalCodeController.dispose();
    _otpController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(bool isGstCertificate) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        if (isGstCertificate) {
          gstCertificateFile = result.files.first;
          gstCertificateFileName = result.files.first.name;
        } else {
          businessLicenseFile = result.files.first;
          businessLicenseFileName = result.files.first.name;
        }
      });
    }
  }

  Future<void> _b2bSignUp() async {
    if (!widget.formKey.currentState!.validate()) return;
    if (!_phoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your phone number first')),
      );
      await _sendPhoneVerificationOtp();
      return;
    }
    if (gstCertificateFile == null || businessLicenseFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both documents.')),
      );
      return;
    }

    try {
      final Map<String, String> fields = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'business_name': _businessNameController.text.trim(),
        'gstin': _gstinController.text.trim(),
        'pan': _panController.text.trim(),
        'phone_number': _phoneNumberController.text.trim(),
        'phone_verified': 'true', // Changed from 'phone verified'
        'verification_otp': _verificationOtp ?? '',
      };

      // Prepare files
      final files = [
        if (gstCertificateFile!.bytes != null)
          http.MultipartFile.fromBytes(
            'gst_certificate',
            gstCertificateFile!.bytes!,
            filename: gstCertificateFileName,
          )
        else if (gstCertificateFile!.path != null)
          await http.MultipartFile.fromPath(
            'gst_certificate',
            gstCertificateFile!.path!,
            filename: gstCertificateFileName,
          )
        else
          throw Exception('GST certificate file is invalid'),
        if (businessLicenseFile!.bytes != null)
          http.MultipartFile.fromBytes(
            'business_license',
            businessLicenseFile!.bytes!,
            filename: businessLicenseFileName,
          )
        else if (businessLicenseFile!.path != null)
          await http.MultipartFile.fromPath(
            'business_license',
            businessLicenseFile!.path!,
            filename: businessLicenseFileName,
          )
        else
          throw Exception('Business license file is invalid'),
      ];

      final response = await ApiService.postMultipart(
        '/auth/register/b2b',
        fields: fields,
        files: files,
      );

      print('B2B SignUp Response: $response');

      if (!mounted) return;

      // Store token in ApiService and Hive
      final accessToken = response['access_token'] as String?;
      if (accessToken != null) {
        ApiService.token = accessToken;
        final authBox = Hive.box('auth');

        await authBox.put('token', accessToken);
        await authBox.put('is_guest', false);
        await authBox.put('phone_verified', true);

        // Save user data
        final businessName = _businessNameController.text.trim();
        final email = _emailController.text.trim();

        await authBox.put('user_name', businessName);
        await authBox.put('user_email', email);
        await authBox.put('user_phone', _phoneNumberController.text.trim());

        // Disable guest mode
        Provider.of<GuestService>(context, listen: false).setGuestMode(false);
        await UserHelper.setUserType(UserHelper.b2b);
        print('✅ B2B Signup: Set user type to B2B');
        // 🔥 LOAD USER-SCOPED CART (B2B)
        final cart = Cart();
        await cart.loadUserCart(email);

        print('🛒 Cart loaded for B2B user: $email');

        // Create address if provided
        final addressLine = _addressController.text.trim();
        if (addressLine.isNotEmpty) {
          final addressPostPayload = {
            'name': 'Primary Business Address',
            'address': addressLine, // Changed from 'street' to 'address'
            'city': _cityController.text.trim(),
            'state': _stateController.text.trim(), // Added state
            'pincode': _postalCodeController.text.trim(),
            'country': _countryController.text.trim(),
            'is_default': true,
          };

          await ApiService.post('/users/addresses', body: addressPostPayload);
          print('✅ B2B Signup: Posted initial address to /users/addresses');
        }

        // --- FIX START: Reload cart after successful B2B signup ---

        print('Token successfully saved to Hive.');
      } else {
        print('Access token was null in the response.');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response['message'] ?? 'B2B Application Submitted!')),
      );

      Navigator.pushNamedAndRemoveUntil(
          context, entryPointScreenRoute, (r) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign Up Failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _sendPhoneVerificationOtp() async {
    final phone =
        ApiService.formatPhoneNumber(_phoneNumberController.text.trim());
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number first')),
      );
      return;
    }

    setState(() => _isSendingOtp = true);

    try {
      final result = await ApiService.sendVerificationOtp(phone);

      setState(() => _isSendingOtp = false);

      if (result['success'] == false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? "Failed to send OTP")),
          );
        }
        return;
      }

      // Proceed to show dialog
      print("✅ OTP sent successfully, showing dialog...");
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      // Show OTP dialog
      String? otp = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => OtpDialog(
          phone: phone,
          onVerify: (otp) => ApiService.verifyOtp(phone, otp),
        ),
      );

      if (otp != null) {
        setState(() {
          _phoneVerified = true;
          _verificationOtp = otp;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Phone verified successfully")),
          );
        }
      }
    } catch (e) {
      setState(() => _isSendingOtp = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sending OTP: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _businessNameController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: "Business Name",
              prefixIcon: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: defaultPadding * 0.75),
                child: SvgPicture.asset(
                  "assets/icons/Profile.svg",
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).textTheme.bodyMedium!.color!,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            validator: (value) => value != null && value.isNotEmpty
                ? null
                : 'Business name is required',
          ),
          Container(height: defaultPadding),

          TextFormField(
            controller: _gstinController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: "GSTIN Number",
              prefixIcon: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: defaultPadding * 0.75),
                child: SvgPicture.asset(
                  "assets/icons/Phone.svg",
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).textTheme.bodyMedium!.color!,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            validator: (value) =>
                value != null && value.isNotEmpty ? null : 'GSTIN is required',
          ),

          Container(height: defaultPadding),

          TextFormField(
            controller: _panController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: "PAN Number",
              prefixIcon: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: defaultPadding * 0.75),
                child: SvgPicture.asset(
                  "assets/icons/Phone.svg",
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).textTheme.bodyMedium!.color!,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            validator: (value) =>
                value != null && value.isNotEmpty ? null : 'PAN is required',
          ),

          Container(height: defaultPadding),

          // Email Field
          TextFormField(
            controller: _emailController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => value != null && value.contains('@')
                ? null
                : 'Enter a valid email',
            decoration: InputDecoration(
              hintText: "Email",
              prefixIcon: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: defaultPadding * 0.75),
                child: SvgPicture.asset(
                  "assets/icons/Message.svg",
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).textTheme.bodyMedium!.color!,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          Container(height: defaultPadding),

          // Password Field
          TextFormField(
            controller: _passwordController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.visiblePassword,
            obscureText: !_showPassword,
            validator: (value) => value != null && value.length >= 6
                ? null
                : 'Password must be at least 6 characters',
            decoration: InputDecoration(
                hintText: "Password",
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: defaultPadding * 0.75),
                  child: SvgPicture.asset(
                    "assets/icons/Lock.svg",
                    height: 24,
                    width: 24,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).textTheme.bodyMedium!.color!,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                )),
          ),

          Container(height: defaultPadding),

          // Phone Number Field
          TextFormField(
            controller: _phoneNumberController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.phone,
            validator: (value) => value != null && value.isNotEmpty
                ? null
                : 'Phone number is required',
            decoration: InputDecoration(
              hintText: "Phone Number",
              prefixIcon: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: defaultPadding * 0.75),
                child: SvgPicture.asset(
                  "assets/icons/Phone.svg",
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).textTheme.bodyMedium!.color!,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              suffixIcon: _phoneVerified
                  ? const Icon(Icons.verified, color: successColor)
                  : null,
            ),
          ),

          Container(height: defaultPadding * 0.5),

          // Verification Button
          if (!_phoneVerified && _phoneNumberController.text.isNotEmpty)
            ElevatedButton(
              onPressed: _isSendingOtp ? null : _sendPhoneVerificationOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                minimumSize: const Size(double.infinity, 45),
              ),
              child: _isSendingOtp
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify Phone Number'),
            ),

          // Verification Status Indicator
          if (!_phoneVerified && _phoneNumberController.text.isNotEmpty)
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              margin: const EdgeInsets.only(top: 8, bottom: defaultPadding),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.9),
                borderRadius: BorderRadius.zero, // No rounding
                border: Border.all(color: kPrimaryColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Phone number not verified. Click "Verify" to receive OTP.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Container(height: defaultPadding),

          // Street
          TextFormField(
            controller: _addressController,
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
            validator: (v) => v == null || v.isEmpty ? "Enter street" : null,
          ),

          Container(height: defaultPadding),

          // City
          TextFormField(
            controller: _cityController,
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
            validator: (v) => v == null || v.isEmpty ? "Enter city" : null,
          ),

          Container(height: defaultPadding),

          // State
          TextFormField(
            controller: _stateController,
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
            validator: (v) => v == null || v.isEmpty ? "Enter state" : null,
          ),

          Container(height: defaultPadding),

          // Postal Code
          TextFormField(
            controller: _postalCodeController,
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
            validator: (v) =>
                v == null || v.isEmpty ? "Enter postal code" : null,
          ),

          Container(height: defaultPadding),

          // Country
          TextFormField(
            controller: _countryController,
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
            validator: (v) => v == null || v.isEmpty ? "Enter country" : null,
          ),

          Container(height: defaultPadding),

          // GST Certificate Upload
          InkWell(
            onTap: () => _pickFile(true),
            child: InputDecorator(
              decoration: InputDecoration(
                hintText: "Upload GST Certificate",
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: defaultPadding * 0.75),
                  child: SvgPicture.asset(
                    "assets/icons/Document.svg",
                    height: 24,
                    width: 24,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).textTheme.bodyMedium!.color!,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                suffixIcon: Icon(
                  Icons.upload_file,
                  color: Theme.of(context).textTheme.bodyMedium!.color!,
                ),
              ),
              child: Text(
                gstCertificateFileName ?? "Upload GST Certificate",
                style: TextStyle(
                  color: gstCertificateFileName != null
                      ? Theme.of(context).textTheme.bodyLarge!.color
                      : Theme.of(context).textTheme.bodyMedium!.color!,
                ),
              ),
            ),
          ),

          Container(height: defaultPadding),

          // Business License Upload
          InkWell(
            onTap: () => _pickFile(false),
            child: InputDecorator(
              decoration: InputDecoration(
                hintText: "Upload Business License",
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: defaultPadding * 0.75),
                  child: SvgPicture.asset(
                    "assets/icons/Document.svg",
                    height: 24,
                    width: 24,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).textTheme.bodyMedium!.color!,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                suffixIcon: Icon(
                  Icons.upload_file,
                  color: Theme.of(context).textTheme.bodyMedium!.color!,
                ),
              ),
              child: Text(
                businessLicenseFileName ?? "Upload Business License",
                style: TextStyle(
                  color: businessLicenseFileName != null
                      ? Theme.of(context).textTheme.bodyLarge!.color
                      : Theme.of(context).textTheme.bodyMedium!.color!,
                ),
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
                          text: "privacy policy.",
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
            onPressed: _agreeToTerms ? _b2bSignUp : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              disabledBackgroundColor: kPrimaryColor,
              disabledForegroundColor: Colors.white.withOpacity(0.5),
            ),
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }
}
