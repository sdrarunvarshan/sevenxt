import 'package:flutter/material.dart';
import 'package:sevenxt/constants.dart';
import 'package:sevenxt/screens/home/views/components/category_section.dart';
import '../../../models/category_model.dart';
import 'components/categories.dart' hide demoCategories;

class GadgetsScreen extends StatelessWidget {
  const GadgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gadgets'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Dynamic category sections - cannot be const
            ..._buildCategorySections(),

            const SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: defaultPadding / 4),
                ],
              ),
            ),

            const SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: defaultPadding * 1.5),
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