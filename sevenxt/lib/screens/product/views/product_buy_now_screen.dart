import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sevenxt/components/cart_button.dart';
import 'package:sevenxt/components/custom_modal_bottom_sheet.dart';
import 'package:sevenxt/components/network_image_with_loader.dart';
import 'package:sevenxt/models/product_model.dart'; // Import ProductModel
import 'package:sevenxt/screens/product/views/added_to_cart_message_screen.dart';
import 'package:sevenxt/screens/product/views/components/product_list_tile.dart';
import 'package:sevenxt/models/cart_model.dart'; // Import CartModel
import 'package:sevenxt/screens/product/views/product_details_screen.dart';


import '../../../constants.dart';
import 'components/product_quantity.dart';
import 'components/selected_colors.dart';

import 'components/unit_price.dart';

class ProductBuyNowScreen extends StatefulWidget {
  // Add product parameter to the constructor
  const ProductBuyNowScreen({super.key, this.product, this.selectedColorIndex});

  final ProductModel? product; // Make it nullable
  final int? selectedColorIndex; // Add selectedColorIndex parameter

  @override
  _ProductBuyNowScreenState createState() => _ProductBuyNowScreenState();
}

class _ProductBuyNowScreenState extends State<ProductBuyNowScreen> {
  late int selectedColorIndex;
  @override
  void initState() {
    super.initState();
    selectedColorIndex = widget.selectedColorIndex ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CartButton(
        price: widget.product?.finalPrice ?? 269.4,
        title: "Add to cart",
        subTitle: "Total price",
        press: () {
          if (widget.product != null) {
            Cart().addItem(widget.product!, widget.product!.colors[selectedColorIndex], weightKg: widget.product!.weightKg, lengthCm: widget.product!.lengthCm, breadthCm: widget.product!.breadthCm, heightCm: widget.product!.heightCm, ); // Add selectedColor parameter
          }
          customModalBottomSheet(
            context,
            isDismissible: false,
            child: const AddedToCartMessageScreen(),
          );
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: defaultPadding / 2, vertical: defaultPadding),
            child: Row(
              // mainAxisAlignment: MainAxisAlignment.spaceBetween, // Removed this line
              children: [
                const BackButton(),
                Expanded(
                  child: Center(
                    child: Text(
                      // Use product title or a default
                      widget.product?.title ?? "Product",
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
                // Add a SizedBox to visually balance the BackButton
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                    child: AspectRatio(
                      aspectRatio: 1.05,
                      // Use product image or a placeholder
                      child: NetworkImageWithLoader(
                        imageUrl: widget.product?.image ?? productDemoImg1,
                        width: double.infinity,
                        height: 250,
                        radius: defaultBorderRadious,
                        fit: BoxFit.cover,
                      )
                      ,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(defaultPadding),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: UnitPrice(
                            // Use product price
                            price: widget.product?.price ?? 145,
                            priceAfterDiscount: widget.product?.priceAfetDiscount,
                            discountPercent: widget.product?.discountPercentUI,

                          ),
                        ),
                        ProductQuantity(
                          numOfItem: 1, // This might need to be managed if it's part of product selection
                          onIncrement: () {},
                          onDecrement: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: Divider()),
                SliverToBoxAdapter(
                  child: SelectedColors(
                  colors: widget.product!.colors,
                    selectedColorIndex: selectedColorIndex , // This part would need to be updated based on available colors for the product
                    press: (value) {
                      setState(() {
                        selectedColorIndex = value;
                      });
                    },
                  ),
                ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: defaultPadding))
              ],
            ),
          )
        ],
      ),
    );
  }
}
