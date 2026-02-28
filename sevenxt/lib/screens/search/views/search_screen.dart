import 'package:flutter/material.dart';
import 'package:sevenxt/components/product/product_card.dart';
import 'package:sevenxt/constants.dart';
import 'package:sevenxt/models/product_model.dart';
import 'package:sevenxt/route/api_service.dart';
import 'package:sevenxt/route/route_constants.dart';
import 'package:sevenxt/screens/helpers/user_helper.dart';
import 'package:sevenxt/screens/search/views/components/search_form.dart';

import '../../../components/skleton/product/products_skelton.dart'; // Import SearchForm

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  late TextEditingController _searchController;
  late Future<List<ProductModel>> _productsFuture;
  String? _userType;
  String _currentSearchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _productsFuture = Future.value([]); // Initialize with an empty list
    _initializeUserType();
  }

  Future<void> _initializeUserType() async {
    try {
      final fetchedUserType = await UserHelper.getUserType();
      setState(() {
        _userType = fetchedUserType;
      });
    } catch (e) {
      print('Error loading user type: $e');
      setState(() {
        _userType = 'b2c'; // Default to b2c if error
      });
    }
  }

  Future<void> _performSearch(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      setState(() {
        _productsFuture = Future.value([]);
        _currentSearchQuery = '';
      });
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentSearchQuery = trimmedQuery;
    });

    try {
      print('=== SEARCH DEBUG INFO ===');
      print('Search query: "$trimmedQuery"');
      print('User type: $_userType');

      // First, try to search without category to get all results
      List<ProductModel> products = await _apiService.searchProducts(
        trimmedQuery,
        userType: _userType,
      );

      // Debug logging
      print('Number of products returned: ${products.length}');
      for (var product in products) {
        print('Product: ${product.title}, Category: ${product.category}');
      }
      print('=== END DEBUG INFO ===');

      // Update the future with the results
      setState(() {
        _productsFuture = Future.value(products);
      });
    } catch (e) {
      print('Error performing search: $e');
      setState(() {
        _productsFuture = Future.error('Failed to load products: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshSearch() async {
    await _performSearch(_currentSearchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 700, // perfect for web
                ),
                child: SearchForm(
                  autofocus: true,
                  controller: _searchController,
                  onFieldSubmitted: (value) {
                    _performSearch(value ?? '');
                  },
                  readOnly: false,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _refreshSearch,
      child: FutureBuilder<List<ProductModel>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          // 1. Check if we are explicitly loading or the future is still waiting
          if (_isLoading ||
              snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          }

          // 2. Check for errors
          if (snapshot.hasError) {
            return _buildErrorScreen(
              'Error loading products',
              errorDetails: snapshot.error.toString(),
              onRetry: _refreshSearch,
            );
          }

          // 3. Extract data and check for empty/null state
          final products = snapshot.data;
          if (products == null || products.isEmpty) {
            if (_currentSearchQuery.isEmpty) {
              return _buildInitialSearchScreen();
            } else {
              return _buildEmptyScreen();
            }
          }

          // 4. At this point, products is guaranteed to be non-null and non-empty
          return _buildProductsGrid(products);
        },
      ),
    );
  }

  Widget _buildInitialSearchScreen() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Start searching for products!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type a keyword in the search bar above.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600, // 👈 nice for empty states on web
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sentiment_dissatisfied_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'No products found for "${_currentSearchQuery}"!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search or check for typos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _refreshSearch,
                child: const Text('Refresh Search'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsGrid(List<ProductModel> products) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 1100) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 700) {
          crossAxisCount = 3;
        }

        double childAspectRatio = switch (crossAxisCount) {
          2 => 0.62, // mobile
          3 => 0.78, // tablet
          _ => 0.95, // desktop
        };

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1300),
            child: GridView.builder(
              padding: const EdgeInsets.all(defaultPadding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: defaultPadding,
                mainAxisSpacing: defaultPadding,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  image: product.image,
                  brandName: product.brandName,
                  title: product.title,
                  price: product.finalPrice, // Use finalPrice (discounted)
                  priceAfetDiscount: null, // Already included in finalPrice
                  rating: product.rating,
                  reviews: product.reviews,
                  dicountpercent: product.discountPercentUI,
                  press: () {
                    Navigator.pushNamed(
                      context,
                      productDetailsScreenRoute,
                      arguments: product,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const ProductsSkelton();
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
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (errorDetails != null) ...[
              SizedBox(height: 8),
              Text(
                errorDetails,
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 24),
            if (onRetry != null)
              SizedBox(
                  width: 350, // or any max width you want
                  child: ElevatedButton(
                    onPressed: onRetry,
                    child: Text('Try Again'),
                  )),
            SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.maybePop(context),
              child: Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
