import 'package:flutter/material.dart';

class ShopCardWidget extends StatelessWidget {
  final double stop;
  final String name;
  final int count;

  const ShopCardWidget({
    super.key,
    required this.stop,
    required this.name,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
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
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(count.toString()),
              ),
            ),
          ),
          Expanded(
            child: FittedBox(
                fit: BoxFit.contain,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(name),
                )),
          )
        ],
      ),
    );
  }
}
