import 'package:flutter/material.dart';

class OtpDialog extends StatefulWidget {
  final String phone;
  // Optional verification callback
  final Future<Map<String, dynamic>> Function(String otp)? onVerify;

  const OtpDialog({super.key, required this.phone, this.onVerify});

  @override
  _OtpDialogState createState() => _OtpDialogState();
}

class _OtpDialogState extends State<OtpDialog> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length < 4) {
      setState(() => _errorMessage = "Enter a valid OTP");
      return;
    }

    if (widget.onVerify != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final result = await widget.onVerify!(otp);
        // Check for success: either explicitly true, or just not explicitly false
        final bool isSuccess = result['success'] == true || 
                             (result.containsKey('message') && result['success'] != false);
        
        if (isSuccess) {
          // Pass the OTP back on success
          if (mounted) Navigator.pop(context, otp);
        } else {
          setState(() {
            _errorMessage = result['message'] ?? result['detail'] ?? "Invalid OTP";
          });
        }
      } catch (e) {
        setState(() {
          // Strip "Exception: " prefix if present
          String error = e.toString();
          if (error.startsWith("Exception: ")) {
            error = error.substring(11);
          }
          _errorMessage = error;
        });
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Legacy behavior: just return the OTP
      Navigator.pop(context, otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Verify Phone"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Enter OTP sent to ${widget.phone}"),
          const SizedBox(height: 16),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "6-digit OTP",
              errorText: _errorMessage,
              counterText: "",
            ),
            onSubmitted: (_) => _handleVerify(),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleVerify,
          child: const Text("Verify"),
        )
      ],
    );
  }
}
