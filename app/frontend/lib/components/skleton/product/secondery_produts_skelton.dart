import 'package:flutter/material.dart';

import '../../../constants.dart';
import 'secondary_product_skelton.dart';

class SeconderyProductsSkelton extends StatelessWidget {
  const SeconderyProductsSkelton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 114,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: defaultPadding),
              child: SeconderyProductSkelton(),
            ),
            Padding(
              padding: EdgeInsets.only(left: defaultPadding),
              child: SeconderyProductSkelton(),
            ),
            Padding(
              padding: EdgeInsets.only(left: defaultPadding, right: defaultPadding),
              child: SeconderyProductSkelton(),
            ),
          ],
        ),
      ),
    );
  }
}
