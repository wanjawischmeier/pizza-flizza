import 'package:flutter/material.dart';
import 'package:pizza_flizza/other/theme.dart';

class CircularAvatarIcon extends StatelessWidget {
  final IconData iconData;
  final EdgeInsetsGeometry padding;

  const CircularAvatarIcon({
    super.key,
    required this.iconData,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: padding,
      decoration: BoxDecoration(
        color: Themes.grayMid,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(2, 2),
          )
        ],
      ),
      child: FittedBox(
        child: Icon(
          iconData,
          color: Themes.cream,
        ),
      ),
    );
  }
}
