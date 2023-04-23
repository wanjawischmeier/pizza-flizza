import 'package:flutter/material.dart';

class ShopCardWidget extends StatelessWidget {
  final double stop;
  final String name;
  final int currentCount;

  const ShopCardWidget({
    super.key,
    required this.stop,
    required this.name,
    required this.currentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.tertiary,
            Theme.of(context).colorScheme.primary
          ],
          stops: [stop, stop],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Text("$name\n$currentCount"),
    );
  }
}
