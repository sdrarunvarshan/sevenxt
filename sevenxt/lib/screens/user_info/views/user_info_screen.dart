import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sevenxt/constants.dart';
import 'package:sevenxt/route/api_service.dart';
import 'package:sevenxt/route/guest_services.dart';

import '/route/screen_export.dart';
import '../../../components/skleton/skelton.dart';
import '../../auth/views/login_screen.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isB2B = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _panController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authBox = Hive.box('auth');
      final token = authBox.get('token');

      if (token == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }

      // Fetch user profile from API
      final profile = await ApiService.getUserProfile();

      // Determine if user is B2B or B2C
      final userType = profile['user_type'] ?? 'b2c';
      _isB2B = userType == 'b2b';

      setState(() {
        _userProfile = profile;
        _isB2B = _isB2B;

        // Initialize controllers with current values
        // For B2B, use business_name as display name if full_name is not available
        if (_isB2B &&
            (profile['full_name'] == null || profile['full_name'].isEmpty)) {
          _nameController.text = profile['business_name'] ?? '';
        } else {
          _nameController.text = profile['full_name'] ?? '';
        }

        _emailController.text = profile['email'] ?? '';
        _phoneController.text = profile['phone_number'] ?? '';
        _businessNameController.text = profile['business_name'] ?? '';
        _gstinController.text = profile['gstin'] ?? '';
        _panController.text = profile['pan'] ?? '';
      });
    } catch (e) {
      print('Error loading profile: $e');

      // Fallback to Hive data
      final authBox = Hive.box('auth');
      final storedName = authBox.get('user_name', defaultValue: 'User');
      final storedEmail = authBox.get('user_email', defaultValue: '');
      final storedPhone = authBox.get('phone_number', defaultValue: '');
      final storedBusiness = authBox.get('business_name', defaultValue: '');

      setState(() {
        _userProfile = {
          'full_name': storedName,
          'email': storedEmail,
          'phone_number': storedPhone,
          'business_name': storedBusiness,
          'user_type': storedBusiness.isNotEmpty ? 'b2b' : 'b2c',
          'created_at': DateTime.now().toIso8601String(), // Fallback date
        };
        _isB2B = storedBusiness.isNotEmpty;
        _nameController.text = storedName;
        _emailController.text = storedEmail;
        _phoneController.text = storedPhone;
        _businessNameController.text = storedBusiness;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_validateFields()) return;

    try {
      // Format phone number: only digits, ensure it starts with 91 for 10-digit numbers
      String rawPhone = _phoneController.text.trim();
      String digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
      String formattedPhone = digits;
      if (digits.length == 10) {
        formattedPhone = '91$digits';
      } else if (digits.length == 12 && digits.startsWith('91')) {
        formattedPhone = digits;
      }

      final Map<String, dynamic> updateData = {
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': formattedPhone,
      };

      if (_isB2B) {
        updateData['business_name'] = _businessNameController.text.trim();
        updateData['gstin'] = _gstinController.text.trim();
        updateData['pan'] = _panController.text.trim();
      }

      // Call your backend API to update profile
      await ApiService.put('/users/me', body: updateData);

      // Update local storage
      final authBox = Hive.box('auth');
      await authBox.put('user_name', _nameController.text.trim());
      await authBox.put('user_email', _emailController.text.trim());
      await authBox.put('phone_number', formattedPhone);
      await authBox.put('user_phone', formattedPhone);

      if (_isB2B && _businessNameController.text.trim().isNotEmpty) {
        await authBox.put('business_name', _businessNameController.text.trim());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      setState(() {
        _isEditing = false;
        _userProfile = {
          ...?_userProfile,
          'full_name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone_number': formattedPhone,
          'business_name': _businessNameController.text.trim(),
          'gstin': _gstinController.text.trim(),
          'pan': _panController.text.trim(),
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  bool _validateFields() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return false;
    }

    if (_isB2B && _businessNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter business name')),
      );
      return false;
    }

    if (_emailController.text.trim().isEmpty ||
        !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return false;
    }

    String phoneDigits =
        _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (phoneDigits.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return false;
    }

    return true;
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Call API to delete account
      await ApiService.delete('/users/me');

      // Clear local storage but preserve has_seen_onboarding
      final authBox = Hive.box('auth');
      await authBox.delete('token');
      await authBox.delete('is_guest');
      await authBox.delete('user_email');
      await authBox.delete('user_phone');
      await authBox.delete('user_name');
      await authBox.delete('is_approved');
      await authBox.delete('business_name');

      // Clear ApiService token
      ApiService.token = null;

      // Disable guest mode
      Provider.of<GuestService>(context, listen: false).setGuestMode(false);

      // Navigate to login screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: $e')),
      );
    }
  }

  Widget _buildInfoTile(String label, String value, {IconData? icon}) {
    return ListTile(
      leading: icon != null
          ? Icon(icon, color: Theme.of(context).primaryColor)
          : null,
      title:
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      dense: true,
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildEditView() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Profile Icon - Centered

        Center(
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              _nameController.text.isNotEmpty
                  ? _nameController.text.substring(0, 1).toUpperCase()
                  : 'U',
              style: const TextStyle(fontSize: 32, color: Colors.white),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Edit Form - This card will now respect the 1200px max width

        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Edit Information",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Divider(height: 32),
                _buildTextField('Full Name', _nameController),
                const SizedBox(height: 10),
                _buildTextField('Email', _emailController),
                const SizedBox(height: 10),
                _buildTextField('Phone Number', _phoneController),
                if (_isB2B) ...[
                  const SizedBox(height: 20),
                  const Text("Business Details",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildTextField('Business Name', _businessNameController),
                  const SizedBox(height: 10),
                  _buildTextField('GSTIN', _gstinController),
                  const SizedBox(height: 10),
                  _buildTextField('PAN Number', _panController),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Save & Cancel Buttons

        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Changes',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewOnly() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // ONE SINGLE CARD
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== PROFILE HEADER =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        _userProfile?['full_name']?.isNotEmpty == true
                            ? _userProfile!['full_name'][0].toUpperCase()
                            : 'U',
                        style:
                            const TextStyle(fontSize: 32, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userProfile?['full_name'] ?? 'User',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userProfile?['email'] ?? '',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(
                            _isB2B ? 'Business Account' : 'Personal Account',
                          ),
                          backgroundColor: kPrimaryColor.withOpacity(0.1),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(),

                // ===== ACCOUNT INFORMATION =====
                const SizedBox(height: 12),
                const Text(
                  'Account Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                _buildInfoTile(
                  'Email',
                  _userProfile?['email'] ?? '',
                  icon: Icons.email_outlined,
                ),
                _buildInfoTile(
                  'Phone',
                  _userProfile?['phone_number'] ?? 'Not provided',
                  icon: Icons.phone_android_outlined,
                ),

                // ===== BUSINESS INFORMATION (B2B ONLY) =====
                if (_isB2B) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Business Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoTile(
                    'Business Name',
                    _userProfile?['business_name'] ?? '',
                    icon: Icons.business_outlined,
                  ),
                  _buildInfoTile(
                    'GSTIN',
                    _userProfile?['gstin'] ?? 'Not provided',
                    icon: Icons.receipt_long_outlined,
                  ),
                  _buildInfoTile(
                    'PAN',
                    _userProfile?['pan'] ?? 'Not provided',
                    icon: Icons.badge_outlined,
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(),

                _buildInfoTile(
                  'Account Created',
                  _formatDate(_userProfile?['created_at']),
                  icon: Icons.calendar_today_outlined,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 30),

        // ===== ACTION BUTTONS =====
        ElevatedButton.icon(
          onPressed: () => setState(() => _isEditing = true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            minimumSize: const Size(double.infinity, 56),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.edit, color: Colors.white),
          label: const Text(
            'Edit Profile',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),

        const SizedBox(height: 12),

        OutlinedButton.icon(
          onPressed: _deleteAccount,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size(double.infinity, 56),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.delete_outline),
          label: const Text(
            'Delete Account',
            style: TextStyle(fontSize: 16),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) {
      // Try alternative date fields
      if (_userProfile?['auth_created_at'] != null) {
        date = _userProfile!['auth_created_at'];
      } else {
        return 'Not available';
      }
    }

    try {
      if (date is String) {
        // Handle different date formats
        DateTime parsed;
        if (date.contains('T')) {
          parsed = DateTime.parse(date);
        } else {
          // Try parsing MySQL datetime format
          parsed = DateTime.parse(date.replaceFirst(' ', 'T'));
        }
        return '${parsed.day}/${parsed.month}/${parsed.year}';
      } else if (date is DateTime) {
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Unknown';
    } catch (e) {
      print('Error parsing date: $date, error: $e');
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profile' : 'Account Details'),
        centerTitle: true, // Better for Web/Desktop headers
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isEditing) {
              setState(() => _isEditing = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      // --- FIX: This Center + ConstrainedBox stops the "Stretching" on Chrome ---
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Skeleton(height: 200, width: double.infinity),
                )
              : _isEditing
                  ? _buildEditView()
                  : _buildViewOnly(),
        ),
      ),
    );
  }
}
