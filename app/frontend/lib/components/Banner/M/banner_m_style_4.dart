import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'banner_m.dart';
import '../../../constants.dart';

class BannerMStyle4 extends StatelessWidget {
  const BannerMStyle4({
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
        Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end, // Changed to end to align with bottom
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,

                ),
              ),
              SizedBox(width: defaultPadding),

            ],
          ),
        ),
      ],
    );
  }
}