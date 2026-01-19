import 'package:flutter/material.dart';
import '../../../../components/product/product_card.dart';
import '../../../../constants.dart';
import '../../../../models/product_model.dart';
import '../../../../route/api_service.dart';
import '../../../../route/route_constants.dart';


class ProductRecommendationsSimple extends StatefulWidget {
  final String productId;
  final String userType;

  const ProductRecommendationsSimple({
    Key? key,
    required this.productId,
    required this.userType,
  }) : super(key: key);

  @override
  State<ProductRecommendationsSimple> createState() => _ProductRecommendationsSimpleState();
}

class _ProductRecommendationsSimpleState extends State<ProductRecommendationsSimple> {
  List<ProductModel> _recommendedProducts = [];
  bool _isLoading = true;
  String? _error;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchRecommendedProducts();
  }

  Future<void> _fetchRecommendedProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final products = await _apiService.getRecommendedProducts(
        widget.productId,
        widget.userType,
        limit: 10,
      );

      setState(() {
        _recommendedProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 280, // Increased height to prevent overflow
          child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
        ),
      );
    }

    if (_error != null) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Failed to load recommendations'),
                TextButton(
                  onPressed: _fetchRecommendedProducts,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_recommendedProducts.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 320, // Increased height to accommodate ProductCard content
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _recommendedProducts.length,
          itemBuilder: (context, index) {
            final p = _recommendedProducts[index];
            return Padding(
              padding: EdgeInsets.only(
                left: defaultPadding,
                right: index == _recommendedProducts.length - 1
                    ? defaultPadding : 0,
              ),
              child: ProductCard(
                image: p.image,
                title: p.title,
                brandName: p.brandName,
                price: p.price,
                priceAfetDiscount: p.priceAfetDiscount,
                rating: p.rating,
                reviews: p.reviews,
                dicountpercent: p.discountPercentUI,

                press: () {
                  Navigator.pushReplacementNamed(
                    context,
                    productDetailsScreenRoute,
                    arguments: p,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
