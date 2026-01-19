import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart'; // import your ApiService

class ReturnRefundPolicyScreen extends StatefulWidget {
  const ReturnRefundPolicyScreen({super.key});

  @override
  State<ReturnRefundPolicyScreen> createState() =>
      _ReturnRefundPolicyScreenState();
}

class _ReturnRefundPolicyScreenState extends State<ReturnRefundPolicyScreen> {
  String content = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  Future<void> _fetchContent() async {
    try {
      final Map<String, String> pages = await ApiService.getCmsPagesMap();
      setState(() {
        // Get content by title
        content = pages['Return & Refund Policy'] ?? 'Content not available';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        content = 'Failed to load content';
        isLoading = false;
      });
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch email: $email';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Return & Refund Policy'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _launchEmail('sevenxt2023@gmail.com'),
                child: const Text(
                  'sevenxt2023@gmail.com',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
