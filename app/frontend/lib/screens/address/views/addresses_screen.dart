import 'package:flutter/material.dart';
import 'package:sevenext/constants.dart';
import 'package:sevenext/route/api_service.dart'; // Import ApiService
import 'add_edit_address_screen.dart';

// ──────────────────────────────────────────────────────────────
// Address Model (keep exactly like this)
// ──────────────────────────────────────────────────────────────
class Address {
  final String id;           // addresses.id
  final String userAddressId; // user_addresses.id (the link row)
  final String name;
  final String address; // Renamed from street to address
  final String city;
  final String state; // Added state
  final String postalCode;
  final String country;
  final bool isDefault;

  Address({
    required this.id,
    required this.userAddressId,
    required this.name,
    required this.address, // Renamed from street to address
    required this.city,
    required this.state, // Added state
    required this.postalCode,
    required this.country,
    required this.isDefault,
  });

  // Factory constructor to parse data from API response
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      userAddressId: json['user_address_id'],   // user_addresses.id
      name: json['name'] ?? 'Unnamed',
      address: json['address'] ?? '', // Changed key from 'street' to 'address' and mapped to new field
      city: json['city'] ?? '',
      state: json['state'] ?? '', // Added state parsing
      postalCode: json['pincode'].toString(),
      country: json['country'] ?? '',
      isDefault: json['is_default'] == 1 || json['is_default'] == true,
    );
  }
}

// ──────────────────────────────────────────────────────────────
// AddressesScreen
// ──────────────────────────────────────────────────────────────
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key, required bool isSelectingMode});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<Address> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() => _isLoading = true);

    try {
      // Use ApiService to fetch addresses
      final response = await ApiService.get('/users/addresses');
      // response = { "data": [ ... ] }
      final List data = response['data'];
      final List<Address> loaded = data.map((e) => Address.fromJson(e)).toList();

      if (mounted) {
        setState(() {
          _addresses = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load addresses: $e')),
        );
      }
    }
  }

  // ───── Add New Address ─────
  void _addNewAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditAddressScreen()),
    );
    if (result == true) _fetchAddresses();
  }

  // ───── Edit Address ─────
  void _editAddress(Address address) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditAddressScreen(
          address: address,
          userAddressId: address.userAddressId,
          addressId: address.id,
        ),
      ),
    );
    if (result == true) _fetchAddresses();
  }

  // ───── Delete Address ─────
  void _deleteAddress(String userAddressId, String addressId, bool wasDefault) async {
    try {
      // Use ApiService to delete the address
      // The backend should handle cascading deletes and default address reassignment
      await ApiService.delete('/users/addresses/$userAddressId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address deleted')),
        );
        _fetchAddresses(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Addresses"), centerTitle: true),
      body: _addresses.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("No Addresses Found", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: defaultPadding),
            const Text("You haven't added any addresses yet.", style: TextStyle(color: greyColor)),
            const SizedBox(height: defaultPadding),
            ElevatedButton(
              onPressed: _addNewAddress,
              child: const Text("Add New Address"),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(defaultPadding),
        itemCount: _addresses.length,
        itemBuilder: (context, index) {
          final addr = _addresses[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(addr.name, style: Theme.of(context).textTheme.titleMedium),
                      if (addr.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("Default", style: TextStyle(color: kPrimaryColor, fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("${addr.address}\n${addr.city}, ${addr.state}, ${addr.country} ${addr.postalCode}"), // Used new field 'address'
                  const SizedBox(height: defaultPadding),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _editAddress(addr),
                        child: const Text("Edit"),
                      ),
                      TextButton(
                        onPressed: () => _deleteAddress(addr.userAddressId, addr.id, addr.isDefault),
                        style: TextButton.styleFrom(foregroundColor: errorColor),
                        child: const Text("Delete"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewAddress,
        child: const Icon(Icons.add),
      ),
    );
  }
}