import 'package:flutter/material.dart';
import 'package:sevenxt/components/check_mark.dart';

import '../../../../constants.dart';

class ColorDot extends StatelessWidget {
  const ColorDot({
    super.key,
    required this.color,
    this.isActive = false,
    this.press,
  });
  final Color color;
  final bool isActive;
  final VoidCallback? press;

  @override
  Widget build(BuildContext context) {
    // Determine if we need a border (light grey for white/light colors)
    final bool isLightColor = color == Colors.white;

    return GestureDetector(
      onTap: press,
      child: AnimatedContainer(
        duration: defaultDuration,
        padding: EdgeInsets.all(isActive ? defaultPadding / 4 : 0),
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? kPrimaryColor
                : (isLightColor ? borderColor : Colors.transparent),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color,
            ),
            AnimatedOpacity(
              opacity: isActive ? 1 : 0,
              duration: defaultDuration,
              child: const CheckMark(),
            ),
          ],
        ),
      ),
    );
  }
}
