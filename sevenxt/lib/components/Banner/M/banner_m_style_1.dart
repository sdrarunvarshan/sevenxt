import 'package:flutter/material.dart';

import '../../../constants.dart';
import 'banner_m.dart';

class BannerMStyle1 extends StatelessWidget {
  const BannerMStyle1({
    super.key,
    required this.press,
    required this.image,
  });
  final String? image;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return BannerM(
      image: image!,
      press: press,
      children: [
        Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
              ),
              const Spacer(),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ],
    );
  }
}
