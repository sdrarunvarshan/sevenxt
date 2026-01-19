import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';import 'package:sevenext/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  @override
  Widget build(BuildContext context) {
    final helpSections = [
      {
        "category": "Getting Started",
        "items": [
          {
            "question": "What is Sevenxt2023?",
            "answer":
            "Sevenxt2023 is a B2C and B2B e-commerce platform offering competitive pricing and seamless sevenextping experiences for both individual consumers and business partners."
          },
          ]
      },
      {
        "category": "B2B Users",
        "items": [
          {
            "question": "How do I register as a B2B user?",
            "answer":
                "Select 'B2B' during registration and provide your business details. After submission, your profile will be reviewed by our admin team for approval."
          },
          {
            "question": "Why can't I log in after logging out?",
            "answer":
                "B2B users require admin approval after registration and each logout. Once you log out, you cannot log back in until the admin approves your profile. This ensures security and verification of business accounts."
          },
          {
            "question": "What are the B2B pricing differences?",
            "answer":
                "B2B users receive special wholesale pricing based on bulk orders and business agreements. Pricing is displayed differently in your account compared to B2C users. Contact our sales team for custom quotes."
          },
          {
            "question": "How long does admin approval take?",
            "answer":
                "Admin approval typically takes 24-48 business hours. You'll receive a notification once your profile is approved and you can log in again."
          },
        ]
      },
      {
        "category": "B2C Users",
        "items": [
          {
            "question": "How do I get started as a B2C user?",
            "answer":
            "Register with your details on the app and start browsing products immediately."
          },
        ]
      },
      {
        "category": "Pricing & Billing",
        "items": [
          {
            "question": "Why are prices different for B2B and B2C?",
            "answer": "B2B users receive wholesale pricing based on bulk purchasing and business partnerships. B2C users see standard retail pricing. Pricing is automatically adjusted based on your user type."
          },
          {
            "question": "How are prices displayed in my account?",
            "answer": "Prices are displayed based on your user type. Log in to view pricing specific to your account category (B2C or B2B)."
          },
        ]
      },
      {
        "category": "Account & Security",
        "items": [
          {
            "question": "Is my data secure?",
            "answer": "Yes, we use industry-standard encryption and security protocols to protect your personal and business information."
          },
        ]
      },

    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: helpSections.length,
        itemBuilder: (context, index) {
          final section = helpSections[index];
          final isSupportSection =
              section["category"] == "Support & Contact";

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section["category"] as String,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(
                (section["items"] as List).length,
                    (i) {
                  final item = (section["items"] as List)[i];
                  return _buildHelpItem(
                    question: item["question"],
                    answer: item["answer"],
                    context: context,
                    isSupportContact: isSupportSection &&
                        item["question"] == "How can I contact support?",
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHelpItem({
    required String question,
    required String answer,
    required BuildContext context,
    required bool isSupportContact,
  }) {
    return ExpansionTile(
      key: ValueKey(question),
      title: Text(
        question,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: isSupportContact
              ? _buildSupportRichText(context)
              : Text(
            answer,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportRichText(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Colors.black,
          fontFamily: 'Poppins',
        ),
        children: [
          const TextSpan(
            text:
            "You can contact support at ",
          ),
          TextSpan(
            text: "sevenxt2023@gmail.com",
            style: const TextStyle(
              color: Colors.red,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launchUrl(Uri.parse("mailto:sevenxt2023@gmail.com"));
              },
          ),
          const TextSpan(
            text:
            "\n\nMerchant: SEVENXT ELECTRONICS PRIVATE LIMITED\n"
                "Registered Address: New No.181/1, Old No.80/1 Swamy Naicken Street,\n"
                "Chintadripet, Chennai, Tamil Nadu 600002\n\n"
                "Telephone: ",
          ),
          TextSpan(
            text: "9840129077",
            style: const TextStyle(
              color: Colors.red,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launchUrl(Uri.parse("tel:9840129077"));
              },
          ),
        ],
      ),
    );
  }
}
