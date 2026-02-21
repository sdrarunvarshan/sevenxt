import 'package:flutter/material.dart';
import 'package:sevenxt/constants.dart';
import 'package:sevenxt/route/api_service.dart'; // Import ApiService
import 'package:sevenxt/screens/address/views/addresses_screen.dart';

class AddEditAddressScreen extends StatefulWidget {
  final Address? address;
  final String? userAddressId; // ID of row in user_addresses table (for edit)
  final String? addressId; // ID of row in addresses table (for edit)

  const AddEditAddressScreen({
    super.key,
    this.address,
    this.userAddressId,
    this.addressId,
  });

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController
      _addressController; // Renamed from _streetController to _addressController
  late TextEditingController _cityController;
  late TextEditingController _stateController; // Added state controller
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address?.name ?? '');
    _addressController = TextEditingController(
        text: widget.address?.address ??
            ''); // Updated controller name and used address field from model
    _cityController = TextEditingController(text: widget.address?.city ?? '');
    _stateController =
        TextEditingController(text: widget.address?.state ?? ''); // Added state
    _postalCodeController =
        TextEditingController(text: widget.address?.postalCode ?? '');
    _countryController =
        TextEditingController(text: widget.address?.country ?? '');
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose(); // Disposed new controller name
    _cityController.dispose();
    _stateController.dispose(); // Added dispose
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;

    try {
      final bool isEditing =
          widget.addressId != null && widget.userAddressId != null;

      final Map<String, dynamic> body = {
        'name': _nameController.text.trim(),
        'address': _addressController.text
            .trim(), // Changed key from 'street' to 'address'
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(), // Added state to body
        'pincode': _postalCodeController.text.trim(),
        'country': _countryController.text.trim(),
        'is_default': _isDefault,
      };

      if (isEditing) {
        // EDIT MODE
        await ApiService.put('/users/addresses/${widget.userAddressId}',
            body: body);
      } else {
        // ADD NEW MODE
        await ApiService.post('/users/addresses', body: body);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isEditing ? "Address updated!" : "Address added!")),
      );
      Navigator.pop(context, true); // success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.address != null;

    return Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? "Edit Address" : "Add New Address"),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(defaultPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                              labelText: 'Name (Home, Work, etc.)'),
                          validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: defaultPadding),
                      TextFormField(
                          controller: _addressController,
                          decoration:
                              const InputDecoration(labelText: 'Address Line'),
                          validator: (v) =>
                              v!.isEmpty ? 'Required' : null), // Renamed label
                      const SizedBox(height: defaultPadding),
                      TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(labelText: 'City'),
                          validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: defaultPadding),
                      TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(labelText: 'State'),
                          validator: (v) => v!.isEmpty
                              ? 'Required'
                              : null), // Added State field
                      const SizedBox(height: defaultPadding),
                      TextFormField(
                          controller: _postalCodeController,
                          decoration:
                              const InputDecoration(labelText: 'Postal Code'),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: defaultPadding),
                      TextFormField(
                          controller: _countryController,
                          decoration:
                              const InputDecoration(labelText: 'Country'),
                          validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: defaultPadding),
                      CheckboxListTile(
                        title: const Text("Set as default address"),
                        value: _isDefault,
                        onChanged: (val) => setState(() => _isDefault = val!),
                      ),
                      const SizedBox(height: defaultPadding * 2),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveAddress,
                          child: Text(
                              isEditing ? "Update Address" : "Save Address"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )));
  }
}
