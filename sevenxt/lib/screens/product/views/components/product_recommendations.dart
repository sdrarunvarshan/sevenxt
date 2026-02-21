import 'package:flutter/material.dart';

import '../../../../components/skleton/product/products_skelton.dart';
import '../../../../models/product_model.dart';
import '../../../../route/api_service.dart';

class ProductRecommendationsSimple extends StatefulWidget {
  final String productId;
  final String userType;

  const ProductRecommendationsSimple({
    Key? key,
    required this.productId,
    required this.userType,
  }) : super(key: key);

  @override
  State<ProductRecommendationsSimple> createState() =>
      _ProductRecommendationsSimpleState();
}

class _ProductRecommendationsSimpleState
    extends State<ProductRecommendationsSimple> {
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
    return const SliverToBoxAdapter(
      child: ProductsSkelton(),
    );
  }
}
