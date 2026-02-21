// lib/screens/home/components/popular_products_tv_entertainment.dart
import 'package:flutter/material.dart';
import 'package:sevenxt/components/product/product_card.dart';
import 'package:sevenxt/models/product_model.dart';
import 'package:sevenxt/route/api_service.dart';
import 'package:sevenxt/route/screen_export.dart';

import '/screens/helpers/user_helper.dart';
import '../../../../components/skleton/product/products_skelton.dart';
import '../../../../constants.dart';

class PopularProductsTVEntertainment extends StatefulWidget {
  const PopularProductsTVEntertainment({super.key});

  @override
  State<PopularProductsTVEntertainment> createState() =>
      _PopularProductsTVEntertainmentState();
}

class _PopularProductsTVEntertainmentState
    extends State<PopularProductsTVEntertainment> {
  final ApiService _apiService = ApiService();
  late Future<List<ProductModel>> _productsFuture;

  final String _category = "TV & Entertainment";

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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: defaultPadding / 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: defaultPadding,
              top: defaultPadding,
              right: defaultPadding,
              bottom: defaultPadding / 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.tv,
                        size: 20,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                          ),
                    ),
                  ],
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
          const SizedBox(height: defaultPadding / 2),
          SizedBox(
            height: 240,
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
                        Icon(
                          Icons.videocam_off,
                          color: Colors.red.shade700,
                          size: 50,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Streaming Error',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load entertainment products',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadProducts,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade50,
                            foregroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.refresh, size: 16),
                              SizedBox(width: 8),
                              Text('Retry'),
                            ],
                          ),
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
                        Icon(
                          Icons.speaker,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Entertainment Products',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back for home theatre systems',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _loadProducts,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.refresh, size: 16),
                              SizedBox(width: 8),
                              Text('Refresh'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final products = snapshot.data!;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: defaultPadding / 2,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.only(
                      left: defaultPadding / 2,
                      right:
                          index == products.length - 1 ? defaultPadding / 2 : 0,
                    ),
                    child: SizedBox(
                      width: 180,
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
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: defaultPadding),
        ],
      ),
    );
  }
}
