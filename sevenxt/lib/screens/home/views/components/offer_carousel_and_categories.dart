import 'package:flutter/material.dart';
import 'package:sevenxt/screens/home/views/components/categories.dart';

import '../../../../constants.dart';
import 'offers_carousel.dart';

class OffersCarouselAndCategories extends StatelessWidget {
  const OffersCarouselAndCategories({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Remove the internal width calculation as the parent (HomeScreen)
    // is already providing a maxWidth constraint.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OffersCarousel(),
        // The OffersCarousel will now naturally respect the maxWidth
        // provided by the ConstrainedBox in HomeScreen.
        const SizedBox(height: defaultPadding / 2),
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Text(
            "Categories",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const Categories(),
      ],
    );
  }
}
