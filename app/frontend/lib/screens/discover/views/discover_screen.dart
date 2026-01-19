import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sevenext/constants.dart';
import 'package:sevenext/models/category_model.dart';
import 'package:sevenext/screens/discover/category_images_provider.dart';
import 'package:sevenext/route/route_constants.dart';
import 'package:sevenext/screens/search/views/components/search_form.dart';
import 'components/expansion_category.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  bool _hasFetched = false; // Prevents multiple fetches

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Fetch category images only once when the screen first appears
    if (!_hasFetched) {
      _hasFetched = true;
      context.read<CategoryImagesProvider>().fetchCategoryImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Form
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: SearchForm(
                readOnly: true,
                onTap: () => Navigator.pushNamed(context, searchScreenRoute),
              ),
            ),

            // "Categories" Title
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: defaultPadding,
                vertical: defaultPadding / 2,
              ),
              child: Text(
                "Categories",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Main Content: Category List with Dynamic Images
            Expanded(
              child: Consumer<CategoryImagesProvider>(
                builder: (context, imagesProvider, child) {
                  // Loading State
                  if (imagesProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Error State
                  if (imagesProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          const Text("Failed to load category images"),
                          TextButton(
                            onPressed: () =>
                                imagesProvider.fetchCategoryImages(),
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    );
                  }

                  // Success: Show Categories
                  return ListView.builder(
                    itemCount: demoCategories.length,
                    itemBuilder: (context, index) {
                      final category = demoCategories[index];

                      // Try to get dynamic image from API (case-insensitive match)
                      final String? dynamicImage =
                      imagesProvider.getImageForCategory(category.name);

                      // Fallback to static image from demoCategories, then empty string
                      final String displayImage =
                          dynamicImage ?? category.image ?? '';

                      return ExpansionCategory(
                        svgSrc:
                        category.svgSrc ?? "assets/icons/Category.svg",
                        title: category.name,
                        image: displayImage, // Uses Unsplash image if available
                        onCategoryTap: () {
                          final routeName =
                              category.route ?? categoryProductsScreen;
                          final arguments = routeName == gadgetsScreenRoute
                              ? true
                              : category.name;

                          Navigator.pushNamed(
                            context,
                            routeName,
                            arguments: arguments,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}