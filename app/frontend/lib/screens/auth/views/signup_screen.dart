import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sevenext/screens/auth/views/components/user_sign_up_form.dart';
import 'package:sevenext/screens/auth/views/components/b2b_sign_up_form.dart';
import 'package:sevenext/route/route_constants.dart';

import '../../../constants.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isB2BRegistration = false;
  bool _agreeToTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              "assets/images/signUp_dark.png",
              height: MediaQuery.of(context).size.height * 0.35,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Let's get started!",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  const Text(
                    "Please enter your valid data in order to create an account.",
                  ),
                  const SizedBox(height: defaultPadding),
                  _isB2BRegistration
                      ? B2BSignUpForm(formKey: _formKey)
                      : UserSignUpForm(
                    formKey: _formKey,
                    agreeToTerms: _agreeToTerms,
                  ),
                  const SizedBox(height: defaultPadding),
                  // Terms and conditions checkbox only for user registration
                  if (!_isB2BRegistration)

                  const SizedBox(height: defaultPadding),
                  // Button to switch to B2B form
                  if (!_isB2BRegistration)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isB2BRegistration = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                      ),
                      child: Text(
                        "Continue as B2B",
                        style: TextStyle(
                          color: whiteColor,
                        ),
                      ),
                    ),
                  const SizedBox(height: defaultPadding),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Do you have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, logInScreenRoute);
                        },
                        child: const Text("Log in"),
                      )
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
