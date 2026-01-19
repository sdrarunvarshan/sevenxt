// lib/screens/home/components/best_sellers.dart
import 'package:flutter/material.dart';
import 'package:sevenext/components/product/product_card.dart';
import 'package:sevenext/models/product_model.dart';
import 'package:sevenext/route/api_service.dart';
import '/screens/helpers/user_helper.dart';
import '../../../../constants.dart';
import '../../../../route/route_constants.dart';

class BestSellers extends StatefulWidget {
  const BestSellers({super.key});

  @override
  State<BestSellers> createState() => _BestSellersState();
}

class _BestSellersState extends State<BestSellers> {
  final ApiService _apiService = ApiService();
  late Future<List<ProductModel>> _bestSellersFuture;
  final String _category = "Wearables";
  @override
  void initState() {
    super.initState();
    // Initialize with empty list first
    _bestSellersFuture = Future.value([]);
    // Then load actual data
    _loadBestSellers();
  }

  Future<void> _loadBestSellers() async {
    try {
      final userType = await UserHelper.getUserType();
      setState(() {
        // CHANGED: Filter specifically for Wearables category
        _bestSellersFuture = _apiService.getProductsByCategory('Wearables', userType);
      });
    } catch (e) {
      print('Error loading best sellers: $e');
      setState(() {
        _bestSellersFuture = Future.value([]);
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
            future: _bestSellersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 40),
                      const SizedBox(height: 8),
                      const Text('Error loading wearables'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadBestSellers,
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
                      const Icon(Icons.leaderboard_outlined, size: 40),
                      const SizedBox(height: 8),
                      const Text('No wearables found'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadBestSellers,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                );
              }

              final wearables = snapshot.data!;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: wearables.length,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(
                    left: defaultPadding,
                    right: index == wearables.length - 1
                        ? defaultPadding
                        : 0,
                  ),
                  child: ProductCard(
                    image: wearables[index].image,
                    brandName: wearables[index].brandName,
                    title: wearables[index].title,
                    price: wearables[index].price.toDouble(),
                    priceAfetDiscount: wearables[index].priceAfetDiscount?.toDouble(),
                    rating: wearables[index].rating,
                    reviews: wearables[index].reviews,
                    press: () {
                      Navigator.pushNamed(
                        context,
                        productDetailsScreenRoute,
                        arguments: wearables[index],
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