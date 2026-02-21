// lib/screens/home/components/popular_products_cameras.dart
import 'package:flutter/material.dart';
import 'package:sevenxt/components/product/product_card.dart';
import 'package:sevenxt/models/product_model.dart';
import 'package:sevenxt/route/api_service.dart';
import 'package:sevenxt/route/screen_export.dart';

import '/screens/helpers/user_helper.dart';
import '../../../../components/skleton/product/products_skelton.dart';
import '../../../../constants.dart';

class PopularProductsCameras extends StatefulWidget {
  const PopularProductsCameras({super.key});

  @override
  State<PopularProductsCameras> createState() => _PopularProductsCamerasState();
}

class _PopularProductsCamerasState extends State<PopularProductsCameras> {
  final ApiService _apiService = ApiService();
  late Future<List<ProductModel>> _productsFuture;

  // Define the category for cameras and photography
  final String _category = "Cameras & Photography";

  @override
  void initState() {
    super.initState();
    _productsFuture = Future.value([]);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final userType = await UserHelper.getUserType();
      setState(() {
        // Call the method to get products by category
        _productsFuture =
            _apiService.getProductsByCategory(_category, userType);
      });
    } catch (e) {
      setState(() {
        _productsFuture = Future.value([]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _category, // Display the category name
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: _loadProducts,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: FutureBuilder<List<ProductModel>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ProductsSkelton();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 40),
                      const SizedBox(height: 8),
                      Text('Error loading $_category'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadProducts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined,
                          size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text('No $_category found'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadProducts,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                );
              }

              final products = snapshot.data!;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(
                    left: defaultPadding,
                    right: index == products.length - 1 ? defaultPadding : 0,
                  ),
                  child: ProductCard(
                    image: products[index].image,
                    brandName: products[index].brandName,
                    title: products[index].title,
                    price: products[index].price.toDouble(),
                    priceAfetDiscount:
                        products[index].priceAfetDiscount?.toDouble(),
                    rating: products[index].rating,
                    reviews: products[index].reviews,
                    press: () {
                      Navigator.pushNamed(
                        context,
                        productDetailsScreenRoute,
                        arguments: products[index],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: defaultPadding),
      ],
    );
  }
}
