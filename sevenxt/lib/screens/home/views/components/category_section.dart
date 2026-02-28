import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sevenxt/components/product/secondary_product_card.dart';
import 'package:sevenxt/models/category_model.dart';
import 'package:sevenxt/models/product_model.dart';
import 'package:sevenxt/route/api_service.dart';

import '/screens/helpers/user_helper.dart';
import '../../../../constants.dart';
import '../../../../route/route_constants.dart';

class CategorySection extends StatefulWidget {
  final CategoryModel category;

  const CategorySection({
    super.key,
    required this.category,
  });

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  final ApiService _apiService = ApiService();
  late Future<List<ProductModel>> _productsFuture;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
  }

  Future<List<ProductModel>> _fetchProducts() async {
    final userType = await UserHelper.getUserType();
    return _apiService.getProductsByCategory(
      widget.category.name,
      userType,
    );
  }

  void _loadProducts() {
    setState(() {
      _productsFuture = _fetchProducts();
    });
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
                widget.category.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  // IMPORTANT: When navigating, just pass the category name as an argument
                  // The CategoryProductsScreen will extract it from route arguments
                  Navigator.pushNamed(
                    context,
                    categoryProductsScreen,
                    arguments: widget.category.name, // Pass as argument
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
            child: Stack(children: [
              FutureBuilder<List<ProductModel>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: kPrimaryColor));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error loading ${widget.category.name}',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loadProducts,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                        child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 24),
                          const SizedBox(height: 8),
                          Text('No ${widget.category.name} found'),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loadProducts,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text('Refresh'),
                                ),
                              ))
                        ],
                      ),
                    ));
                  }

                  final products = snapshot.data!;

                  return ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.only(
                        left: defaultPadding,
                        right:
                            index == products.length - 1 ? defaultPadding : 0,
                      ),
                      child: SecondaryProductCard(
                        image: products[index].image,
                        brandName: products[index].brandName,
                        title: products[index].title,
                        price: products[index].price,
                        rating: products[index].rating,
                        priceAfetDiscount: products[index].priceAfetDiscount,
                        dicountpercent: products[index].discountPercentUI,
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
              Positioned(
                left: 0,
                top: 40,
                child: IconButton(
                  onPressed: () {
                    _scrollController.animateTo(
                      _scrollController.offset - 150,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: SvgPicture.asset(
                    'assets/icons/miniLeft.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),

              /// ▶ RIGHT ARROW
              Positioned(
                right: 0,
                top: 40,
                child: IconButton(
                  onPressed: () {
                    _scrollController.animateTo(
                      _scrollController.offset + 150,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: SvgPicture.asset(
                    'assets/icons/miniRight.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ]))
      ],
    );
  }
}
