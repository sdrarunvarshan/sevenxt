// screens/returns/return_request_screen.dart
import 'dart:io' show File;
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sevenxt/constants.dart';
import 'package:sevenxt/models/order_model.dart';

import '../../../models/return_model.dart';
import '../../product/views/components/returns_repository.dart';
// default to refund

class ReturnRequestScreen extends StatefulWidget {
  final Order order;
  final OrderedProduct product;
  final ReturnType initialType;

  const ReturnRequestScreen({
    super.key,
    required this.order,
    required this.product,
    this.initialType = ReturnType.refund,
  });

  @override
  State<ReturnRequestScreen> createState() => _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends State<ReturnRequestScreen> {
  late TextEditingController _detailsController;
  int _selectedQuantity = 1;
  String _selectedReason = '';
  String _additionalDetails = '';
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  late ReturnType _selectedType;
  late TextEditingController _otherReasonController;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _detailsController = TextEditingController();
    _otherReasonController = TextEditingController();
    if (widget.product.quantity < 1) {
      _selectedQuantity = 0;
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _otherReasonController.dispose();
    super.dispose();
  }

  final List<String> _returnReasons = [
    'Wrong item delivered',
    'Item damaged',
    'Quality not as expected',
    'Changed my mind',
    'Wrong size',
    'Better price available',
    'Item missing / incomplete',
    'Received different color / variant',
    'Delivered too late',
    'Packaging damaged',
    'Does not fit as expected',
    'Product not as described',
    'Other',
  ];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() {
      _selectedImages.add(image);
    });
  }

  Future<void> _submitReturnRequest() async {
    // 1️⃣ Reason validation
    if (_selectedReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason for return'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    if (_selectedReason == 'Other' &&
        _otherReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify your return reason'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    // 2️⃣ Additional details validation
    if (_detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide additional details'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    // 3️⃣ Image upload validation
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one image'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }
    // Resolve final reason (handle "Other")
    final String finalReason = _selectedReason == 'Other'
        ? _otherReasonController.text.trim()
        : _selectedReason;

    setState(() {
      _isSubmitting = true;
    });
    try {
      // In a real app, you would upload images to a server
      // For now, we'll just update the order status locally
      if (widget.order.products.isNotEmpty) {
        await ReturnsRepository.submitReturnRequest(
          order: widget.order,
          product: widget.product, // Pass the orderItemId
          reason: finalReason,
          quantity: _selectedQuantity,
          details: _additionalDetails,
          images: _selectedImages,
          type: _selectedType,
        );
      } else {
        // Handle the case where there are no products in the order
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Order has no products to return.'),
          backgroundColor: errorColor,
        ));
        return;
      }
      // Update order status to "return requested"
      // You need to implement this method in OrdersRepository
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return request submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit return request: ${e.toString()}'),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedType == ReturnType.exchange
            ? "Request Exchange"
            : "Request Return"),
        centerTitle: true,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.all(defaultPadding),
            children: [
              // Order Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order #${widget.order.id}",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Placed on: ${DateFormat('dd MMM yyyy').format(widget.order.placedOn)}",
                        style: const TextStyle(color: greyColor),
                      ),
                      Text(
                        "Total: \u20B9${widget.order.totalPrice.toStringAsFixed(2)}",
                        style: const TextStyle(color: greyColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: defaultPadding),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Quantity to ${_selectedType == ReturnType.exchange ? 'Exchange' : 'Return'}",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Decrease Button
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _selectedQuantity > 1
                                ? () => setState(() => _selectedQuantity--)
                                : null,
                          ),
                          // Quantity Display
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _selectedQuantity.toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          // Increase Button
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed:
                                _selectedQuantity < widget.product.quantity
                                    ? () => setState(() => _selectedQuantity++)
                                    : null,
                          ),
                          const Spacer(),
                          Text(
                            "Available: ${widget.product.quantity}",
                            style: const TextStyle(color: greyColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: defaultPadding),

              // Reason for Return
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Reason for ${_selectedType == ReturnType.exchange ? 'Exchange' : 'Return'}",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ..._returnReasons.map((reason) {
                        return RadioListTile<String>(
                          title: Text(reason),
                          value: reason,
                          groupValue: _selectedReason,
                          onChanged: (value) {
                            setState(() {
                              _selectedReason = value!;
                              if (value != 'Other') {
                                _otherReasonController.clear();
                              }
                            });
                          },
                        );
                      }).toList(),
                      if (_selectedReason == 'Other') ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _otherReasonController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Please specify your reason',
                            hintText: 'Enter your reason...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: defaultPadding),

              // Additional Details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Attach Details (order item, issue description)",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _detailsController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Describe the issue in detail...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _additionalDetails = value;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: defaultPadding),

              // Upload Images
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Upload Images",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Upload images showing the issue (max 5)",
                        style: const TextStyle(color: greyColor),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._selectedImages.map((xFile) {
                            return Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: kIsWeb
                                          ? NetworkImage(xFile.path)
                                          : FileImage(File(xFile.path))
                                              as ImageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () {
                                      setState(() {
                                        _selectedImages.remove(xFile);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                          if (_selectedImages.length < 5)
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: greyColor),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 32,
                                  color: greyColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: defaultPadding * 2),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Request Type",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      RadioListTile<ReturnType>(
                        title: const Text("Refund"),
                        value: ReturnType.refund,
                        groupValue: _selectedType,
                        onChanged: (value) {
                          setState(() => _selectedType = value!);
                        },
                      ),
                      RadioListTile<ReturnType>(
                        title: const Text("Exchange"),
                        value: ReturnType.exchange,
                        groupValue: _selectedType,
                        onChanged: (value) {
                          setState(() => _selectedType = value!);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: defaultPadding),
              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReturnRequest,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: kPrimaryColor)
                    : Text(
                        "Submit ${_selectedType == ReturnType.exchange ? 'Exchange' : 'Return'} Request"),
              ),
              const SizedBox(height: defaultPadding),
            ],
          ),
        ),
      ),
    );
  }
}
