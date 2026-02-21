import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sevenxt/components/custom_modal_bottom_sheet.dart';
import 'package:sevenxt/components/product/product_card.dart';
import 'package:sevenxt/constants.dart';
import 'package:sevenxt/models/cart_model.dart';
import 'package:sevenxt/models/product_model.dart';
import 'package:sevenxt/route/screen_export.dart';
import 'package:sevenxt/screens/product/views/added_to_cart_message_screen.dart';
import 'package:sevenxt/screens/product/views/components/product_quantity.dart';
import 'package:sevenxt/screens/product/views/components/selected_colors.dart';
import 'package:sevenxt/screens/product/views/components/unit_price.dart';

import '../../../components/review_card.dart';
import '../../../route/api_service.dart';
import '../../helpers/user_helper.dart';
import 'components/product_images.dart';
import 'components/product_info.dart';
import 'components/product_list_tile.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, this.product, this.userType});

  final ProductModel? product;
  final String? userType;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  int _selectedColorIndex = 0;
  List<dynamic> _productReviews = [];
  bool _isLoadingReviews = true;
  ProductModel? _fullProduct;
  bool _isLoadingProduct = true;
  late String? _resolvedUserType;

  @override
  void initState() {
    super.initState();
    _selectedColorIndex =
        (widget.product != null && widget.product!.colors.isNotEmpty) ? 0 : -1;
    _resolvedUserType = widget.userType;

    _loadProductReviews();
    _loadProductDetails();
  }

  final ScrollController _recommendScrollController = ScrollController();

  Future<void> _loadProductReviews() async {
    if (widget.product == null) {
      _isLoadingReviews = false;
      return;
    }

    try {
      final response =
          await ApiService().getProductReviews(widget.product!.id, limit: 5);

      setState(() {
        _productReviews = response['reviews'] ?? [];
        _isLoadingReviews = false;
      });
    } catch (e) {
      debugPrint("❌ Failed to load product reviews: $e");
      _isLoadingReviews = false;
    }
  }

  Future<void> _loadProductDetails() async {
    try {
      String userType = widget.userType ?? 'b2c';

      // If userType is not passed, fetch it from UserHelper
      if (widget.userType == null) {
        userType = await UserHelper.getUserType();
      }

      // Update the resolved user type so it can be used for recommendations
      setState(() {
        _resolvedUserType = userType;
      });

      // IMPORTANT: always fetch by ID
      final product = await ApiService().getProductById(
        widget.product!.id,
        userType: userType,
      );

      setState(() {
        _fullProduct = product;
        _isLoadingProduct = false;
      });
    } catch (e) {
      debugPrint("❌ Failed to load product details: $e");
      setState(() {
        _isLoadingProduct = false;
      });
    }
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _onColorSelected(int index) {
    setState(() {
      _selectedColorIndex = index;
    });
  }

  void _addToCart() {
    if (_fullProduct == null || _selectedColorIndex < 0) return;

    final String selectedColorName = _fullProduct!.colors[_selectedColorIndex];

    Cart().addItem(
      _fullProduct!,
      selectedColorName,
      quantity: _quantity,
      weightKg: _fullProduct!.weightKg,
      hsnCode: _fullProduct!.hsnCode,
      lengthCm: _fullProduct!.lengthCm,
      breadthCm: _fullProduct!.breadthCm,
      heightCm: _fullProduct!.heightCm,
    );

    customModalBottomSheet(
      context,
      isDismissible: false,
      child: const AddedToCartMessageScreen(),
    );
  }

  void _buyNow() {
    if (_fullProduct == null || _selectedColorIndex < 0) return;

    final String selectedColorName = _fullProduct!.colors[_selectedColorIndex];

    Cart().addItem(
      _fullProduct!,
      selectedColorName,
      quantity: _quantity,
      hsnCode: _fullProduct!.hsnCode,
      weightKg: _fullProduct!.weightKg,
      lengthCm: _fullProduct!.lengthCm,
      breadthCm: _fullProduct!.breadthCm,
      heightCm: _fullProduct!.heightCm,
    );

    Navigator.pushNamed(context, cartScreenRoute, arguments: {
      'userType': _resolvedUserType, // ✅ PASS IT
    });
  }

  Map<String, int> _calculateReviewStats() {
    int fiveStar = 0, fourStar = 0, threeStar = 0, twoStar = 0, oneStar = 0;

    for (var review in _productReviews) {
      final rating = review['rating'] ?? 0;
      switch (rating.round()) {
        case 5:
          fiveStar++;
          break;
        case 4:
          fourStar++;
          break;
        case 3:
          threeStar++;
          break;
        case 2:
          twoStar++;
          break;
        case 1:
          oneStar++;
          break;
      }
    }

    return {
      'fiveStar': fiveStar,
      'fourStar': fourStar,
      'threeStar': threeStar,
      'twoStar': twoStar,
      'oneStar': oneStar,
    };
  }

  Widget _buildBottomBar(BuildContext context, ProductModel currentProduct) {
    if (widget.product != null && currentProduct.isAvailable) {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: kBackgroundColor,
          border: Border(
            top: BorderSide(
              color: blackColor20,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _addToCart,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(defaultBorderRadious),
                  ),
                ),
                child: const Text("Add to Cart"),
              ),
            ),
            const SizedBox(width: defaultPadding),
            Expanded(
              child: ElevatedButton(
                onPressed: _buyNow,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(defaultBorderRadious),
                  ),
                ),
                child: const Text("Buy Now"),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(defaultPadding),
        child: Text(
          "Product not available",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProduct) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );
    }

    // ✅ REQUIRED: null protection
    if (_fullProduct == null) {
      return const Scaffold(
        body: Center(child: Text("Product not found")),
      );
    }
    // ✅ THIS LINE FIXES THE ERROR (DO NOT REMOVE)
    final ProductModel currentProduct = _fullProduct!;

    final List<String> imagesToShow =
        (currentProduct.images != null && currentProduct.images!.isNotEmpty)
            ? currentProduct.images!
            : [currentProduct.image];

    final reviewStats = _calculateReviewStats();
    final totalReviews = _productReviews.length;

    return Scaffold(
      bottomNavigationBar: _buildBottomBar(context, currentProduct),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: kBackgroundColor,
              floating: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                currentProduct.title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              actions: [],
            ),

            // Product Images - Wrapped in SliverToBoxAdapter to fix the error
            SliverToBoxAdapter(
              child: SizedBox(
                child: ProductImages(images: imagesToShow),
              ),
            ),

            // Product Info - Already a sliver
            ProductInfo(
              product: currentProduct,
            ),

            // Quantity Selector
            SliverPadding(
              padding: const EdgeInsets.all(defaultPadding),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: UnitPrice(
                        price: currentProduct.price.toDouble(),
                        priceAfterDiscount:
                            currentProduct.priceAfetDiscount?.toDouble(),
                        discountPercent: currentProduct.discountPercentUI,
                      ),
                    ),
                    ProductQuantity(
                      numOfItem: _quantity,
                      onIncrement: _incrementQuantity,
                      onDecrement: _decrementQuantity,
                    ),
                  ],
                ),
              ),
            ),

            // Color Selection
            SliverToBoxAdapter(
              child: SelectedColors(
                colors: currentProduct.colors, // ✅ List<String>
                selectedColorIndex: _selectedColorIndex,
                press: _onColorSelected,
              ),
            ),

            // Product Details Section
            SliverPadding(
              padding: const EdgeInsets.all(defaultPadding),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Product Details",
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    Text(
                      currentProduct.description ??
                          "No detailed description available.",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(defaultPadding),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Return Policy",
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    Text(
                      currentProduct.returnPolicy ??
                          "No return policy available.",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
            // Reviews Section
            ,
            SliverPadding(
              padding: const EdgeInsets.all(defaultPadding),
              sliver: SliverToBoxAdapter(
                child: _isLoadingReviews
                    ? Center(
                        child: CircularProgressIndicator(color: kPrimaryColor))
                    : totalReviews == 0
                        ? Container(
                            padding: const EdgeInsets.all(defaultPadding),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .color!
                                  .withOpacity(0.035),
                              borderRadius:
                                  BorderRadius.circular(defaultBorderRadious),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "No reviews yet",
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Be the first to review this product!",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),

                                /// 🔥 WRITE REVIEW BUTTON
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      productReviewsScreenRoute,
                                      arguments: {
                                        'product': currentProduct,
                                      },
                                    );
                                  },
                                  child: const Text("Write a Review"),
                                ),
                              ],
                            ),
                          )
                        : ReviewCard(
                            rating: currentProduct.rating,
                            numOfReviews: totalReviews,
                            numOfFiveStar: reviewStats['fiveStar'] ?? 0,
                            numOfFourStar: reviewStats['fourStar'] ?? 0,
                            numOfThreeStar: reviewStats['threeStar'] ?? 0,
                            numOfTwoStar: reviewStats['twoStar'] ?? 0,
                            numOfOneStar: reviewStats['oneStar'] ?? 0,
                          ),
              ),
            ),

            // View All Reviews - ProductListTile is already a sliver, so use it directly
            if (totalReviews > 0)
              ProductListTile(
                svgSrc: "assets/icons/Chat.svg",
                title: "View All Reviews ($totalReviews)",
                isShowBottomBorder: true,
                press: () {
                  Navigator.pushNamed(
                    context,
                    productReviewsScreenRoute,
                    arguments: {
                      'product': currentProduct,
                      'reviews': _productReviews,
                      '_selectedColorIndex': _selectedColorIndex,
                    },
                  );
                },
              ),

            // Write a Review - ProductListTile is already a sliver
            // You may also like Section
            SliverPadding(
              padding: const EdgeInsets.all(defaultPadding),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "You may also like",
                          style: Theme.of(context).textTheme.titleSmall!,
                        ),
                      ],
                    ),
                    const SizedBox(height: defaultPadding),
                    // Wrap FutureBuilder in Container with fixed height
                    Container(
                      height: 260, // Give enough height for all states
                      child: FutureBuilder<List<ProductModel>>(
                        future: widget.product != null
                            ? ApiService().getRecommendedProducts(
                                widget.product!.id,
                                _resolvedUserType ?? 'b2c',
                                limit: 10,
                              )
                            : Future.value([]),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                  color: kPrimaryColor),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Unable to load recommendations',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        // Retry loading
                                      });
                                    },
                                    child: const Text('Try again'),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Text(
                                'No recommendations available',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            );
                          }

                          final recommendedProducts = snapshot.data!;

                          return SizedBox(
                            height: 260, // adjust based on ProductCard height
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 🔹 Product List
                                ListView.separated(
                                  controller: _recommendScrollController,
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40),
                                  itemCount: recommendedProducts.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(width: defaultPadding),
                                  itemBuilder: (context, index) {
                                    final p = recommendedProducts[index];
                                    return SizedBox(
                                      width: 150,
                                      child: ProductCard(
                                        image: p.image,
                                        title: p.title,
                                        brandName: p.brandName,
                                        price: p.price.toDouble(),
                                        priceAfetDiscount:
                                            p.priceAfetDiscount?.toDouble(),
                                        dicountpercent: p.discountPercentUI,
                                        rating: p.rating,
                                        reviews: p.reviews,
                                        press: () {
                                          Navigator.pushNamed(
                                            context,
                                            productDetailsScreenRoute,
                                            arguments: p,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),

                                // 🔹 Left Arrow
                                Positioned(
                                  left: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      _recommendScrollController.animateTo(
                                        _recommendScrollController.offset -
                                            200, // scroll left
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                      );
                                    },
                                    child: SvgPicture.asset(
                                      "assets/icons/miniLeft.svg",
                                      height: 28,
                                      width: 28,
                                    ),
                                  ),
                                ),

                                // 🔹 Right Arrow
                                Positioned(
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      _recommendScrollController.animateTo(
                                        _recommendScrollController.offset +
                                            200, // scroll right
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                      );
                                    },
                                    child: SvgPicture.asset(
                                      "assets/icons/miniRight.svg",
                                      height: 28,
                                      width: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
