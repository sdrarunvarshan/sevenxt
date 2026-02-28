// lib/screens/home/components/most_popular.dart
import 'package:flutter/material.dart';
import 'package:sevenxt/components/product/secondary_product_card.dart';
import 'package:sevenxt/models/product_model.dart';
import 'package:sevenxt/route/api_service.dart';

import '/screens/helpers/user_helper.dart';
import '../../../../components/skleton/product/secondery_produts_skelton.dart';
import '../../../../constants.dart';
import '../../../../route/route_constants.dart';

class MostPopular extends StatefulWidget {
  const MostPopular({super.key});

  @override
  State<MostPopular> createState() => _MostPopularState();
}

class _MostPopularState extends State<MostPopular> {
  final ApiService _apiService = ApiService();
  late Future<List<ProductModel>> _mostPopularProductsFuture;

  // Define the category you want to display
  final String _category = "Mobile & Devices";

  @override
  void initState() {
    super.initState();
    _loadMostPopularProducts();
  }

  Future<void> _loadMostPopularProducts() async {
    try {
      final userType = await UserHelper.getUserType();
      setState(() {
        // Call getProductsByCategory instead of getPopularProducts
        _mostPopularProductsFuture =
            _apiService.getProductsByCategory(_category, userType);
      });
    } catch (e) {
      // Handle error - you might want to show an error state
      setState(() {
        _mostPopularProductsFuture = Future.value([]);
      });
      print('Error loading products: $e');
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
                onPressed: () {
                  // Navigate to CategoryProductsScreen and pass the category name
                  Navigator.pushNamed(
                    context,
                    categoryProductsScreen,
                    arguments: _category,
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 114,
          child: FutureBuilder<List<ProductModel>>(
            future: _mostPopularProductsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SeconderyProductsSkelton();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: errorColor, size: 24),
                      const SizedBox(height: 8),
                      Text('Error loading $_category'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadMostPopularProducts,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
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
                      const Icon(Icons.phone_iphone_outlined, size: 24),
                      const SizedBox(height: 8),
                      Text('No $_category found'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadMostPopularProducts,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                );
              }

              final mostPopularProducts = snapshot.data!;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: mostPopularProducts.length,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(
                    left: defaultPadding,
                    right: index == mostPopularProducts.length - 1
                        ? defaultPadding
                        : 0,
                  ),
                  child: SecondaryProductCard(
                    image: mostPopularProducts[index].image,
                    brandName: mostPopularProducts[index].brandName,
                    title: mostPopularProducts[index].title,
                    price: mostPopularProducts[index].price.toDouble(),
                    priceAfetDiscount: mostPopularProducts[index]
                        .priceAfetDiscount
                        ?.toDouble(),
                    press: () {
                      Navigator.pushNamed(
                        context,
                        productDetailsScreenRoute,
                        arguments: mostPopularProducts[index],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
