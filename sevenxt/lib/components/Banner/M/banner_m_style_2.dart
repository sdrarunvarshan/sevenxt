import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'banner_m.dart';
import '../../../constants.dart';

class BannerMStyle2 extends StatelessWidget {
  const BannerMStyle2({
    super.key,
    required this.image,
    required this.press,

  });

  final String? image;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return BannerM(
      image: image!,
      press: press,
      children: const [
        // -------------------------------------------------
        // 1. Stack → absolute positioning for the tag
        // -------------------------------------------------
        Stack(
          children: [
            // -------------------------------------------------
            // 2. Main content (title, subtitle, button)
            // -------------------------------------------------
            Padding(
              padding: EdgeInsets.all(defaultPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Text column – aligned to the **start**
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: defaultPadding / 2), // reserve space for the tag


                      ],
                    ),
                  ),
                  SizedBox(width: defaultPadding),
                  // Arrow button

                ],
              ),
            ),

            // -------------------------------------------------
            // 3. Discount tag – **center horizontally**, **top**
            // -------------------------------------------------

          ],
        ),
      ],
    );
  }
}