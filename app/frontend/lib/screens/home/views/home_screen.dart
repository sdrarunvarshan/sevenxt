import 'package:flutter/material.dart';
import 'package:sevenext/constants.dart';
import 'package:sevenext/screens/home/views/components/category_section.dart';
import '../../../models/category_model.dart';
import 'components/offer_carousel_and_categories.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Check for route arguments. If arguments are present (e.g., when navigating 
    // from a category button like "All Gadgets"), we assume we should hide the carousel.
    final args = ModalRoute.of(context)?.settings.arguments;
    // Show carousel ONLY if no arguments are passed (i.e., navigating directly to home).
    final bool showCarouselAndCategories = args == null;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            if (showCarouselAndCategories) // Conditionally include the carousel
              const SliverToBoxAdapter(child: OffersCarouselAndCategories()),
            
            // Dynamic category sections - cannot be const
            ..._buildCategorySections(),

            const SliverToBoxAdapter(
              child: Column(
                children: [
                  // While loading use 👇
                  // const BannerMSkelton(),

                  SizedBox(height: defaultPadding / 4),
                  // We have 4 banner styles, all in the pro version
                ],
              ),
            ),

            // Old static category sections - now replaced by dynamic ones
            // SliverToBoxAdapter(child: PopularProductsCameras()),
            // SliverToBoxAdapter(child: PopularProductsNetworking()),
            // SliverToBoxAdapter(child: PopularProductsPeripherals()),
            // SliverToBoxAdapter(child: PopularProductsTVEntertainment()),


            const SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: defaultPadding * 1.5),

                  SizedBox(height: defaultPadding / 4),
                  // While loading use 👇
                  // const BannerSSkelton(),

                  SizedBox(height: defaultPadding / 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds dynamic category sections for all categories except "All Gadgets"
  static List<Widget> _buildCategorySections() {
    // Filter out "All Gadgets" category
    // IMPORTANT: Make sure demoCategories is accessible in this file
    // You might need to import it if it's not already available
    final filteredCategories = demoCategories.where(
            (category) => category.name != "All Gadgets"
    ).toList();

    // Create a CategorySection for each remaining category
    return filteredCategories.map((category) {
      return SliverToBoxAdapter(
        child: CategorySection(
          category: category,
        ),
      );
    }).toList();
  }
}