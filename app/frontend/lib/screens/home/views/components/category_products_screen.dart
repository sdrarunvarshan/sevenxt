import 'package:flutter/material.dart';import 'package:sevenext/constants.dart';import 'package:sevenext/models/product_model.dart';import 'package:sevenext/route/api_service.dart';import 'package:sevenext/route/route_constants.dart';import 'package:sevenext/screens/helpers/user_helper.dart';import 'package:sevenext/components/network_image_with_loader.dart';


class CategoryProductsScreen extends StatefulWidget {
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<ProductModel>> _productsFuture;
  String? _userType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _productsFuture = Future.value([]);
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      await _loadUserType();
      await _loadProducts();
    } catch (e) {
      print('Error initializing screen: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadUserType() async {
    try {
      final fetchedUserType = await UserHelper.getUserType();
      setState(() {
        _userType = fetchedUserType;
      });
    } catch (e) {
      print('Error loading user type: $e');
      setState(() {
        _userType = 'b2c';
      });
    }
  }

  Future<void> _loadProducts({String? userType}) async {
    final effectiveUserType = userType ?? _userType ?? 'b2c';
    try {
      setState(() {
        _productsFuture = _apiService.getProductsByCategory(
          widget.categoryName,
          '',
          userType: effectiveUserType,
        );
      });
    } catch (e) {
      print('Error setting products future: $e');
      setState(() {
        _productsFuture = Future.value([]);
      });
    }
  }

  Future<void> _refreshProducts() async {
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: FutureBuilder<List<ProductModel>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (_isLoading || snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen();
            }

            if (snapshot.hasError) {
              return _buildErrorScreen(
                'Error loading products',
                errorDetails: snapshot.error.toString(),
                onRetry: _refreshProducts,
              );
            }

            final products = snapshot.data;
            if (products == null || products.isEmpty) {
              return _buildEmptyScreen();
            }

            return _buildProductsGrid(products);
          },
        ),
      ),
    );
  }

  Widget _buildProductsGrid(List<ProductModel> products) {
    return Column(
      children: [
        if (_userType != null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.sevenextping_bag,
                  size: 16,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  '${products.length} products found',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
              // childAspectRatio: width / height
              // A lower value makes the card taller.
              // 0.40 means Height = Width / 0.40 = 2.5 * Width.
              // This provides ample space for image (square) + text content.
              return GridView.builder(
                padding: const EdgeInsets.all(defaultPadding),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.4, 
                  crossAxisSpacing: defaultPadding,
                  mainAxisSpacing: defaultPadding,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(defaultBorderRadious),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        productDetailsScreenRoute,
                        arguments: product,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(defaultBorderRadious),
                        boxShadow: [
                          BoxShadow(
                            color: blackColor20,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// IMAGE SECTION
                          AspectRatio(
                            aspectRatio: 1.0,
                            child: Stack(
                              children: [
                                NetworkImageWithLoader(imageUrl: product.image, radius: 0),
                                if (product.discountPercentUI != null && product.discountPercentUI! > 0)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: errorColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "${product.discountPercentUI}% OFF",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          /// CONTENT SECTION
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (product.brandName.isNotEmpty)
                                    Text(
                                      product.brandName.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 2),
                                  Text(
                                    product.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Colors.grey[800],
                                    ),
                                    maxLines: 2, 
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  
                                  const Spacer(),
                                  
                                  // PRICE SECTION
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (product.hasDiscount)
                                        Text(
                                          '₹${product.price.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      Text(
                                        '₹${product.finalPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: kPrimaryColor),
          const SizedBox(height: 16),
          const Text('Loading products...'),
        ],
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sentiment_dissatisfied_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No products found in "${widget.categoryName}"!',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try refreshing or check another category.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshProducts,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(
      String message, {
        String? errorDetails,
        VoidCallback? onRetry,
      }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            if (errorDetails != null) ...[
              const SizedBox(height: 8),
              Text(errorDetails,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            if (onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
