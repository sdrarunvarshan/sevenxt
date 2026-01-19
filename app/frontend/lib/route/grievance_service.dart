import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';

class GrievanceRedressalScreen extends StatefulWidget {
  const GrievanceRedressalScreen({super.key});

  @override
  State<GrievanceRedressalScreen> createState() =>
      _GrievanceRedressalScreenState();
}

class _GrievanceRedressalScreenState
    extends State<GrievanceRedressalScreen> {
  String content = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  Future<void> _fetchContent() async {
    try {
      final Map<String, String> pages =
      await ApiService.getCmsPagesMap();

      setState(() {
        content =
            pages['Grievance Redressal Policy'] ?? 'Content not available';
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
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grievance Redressal'),
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
                onTap: () =>
                    _launchEmail('sevenxt2023@gmail.com'),
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
