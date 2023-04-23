import 'package:flutter/material.dart';
import 'package:pizza_flizza/widgets/order_card.dart';

class OrderFragment extends StatelessWidget {
  const OrderFragment({super.key});

  static const Map<String, double> items = <String, double>{
    'pizza': 1.2,
    'apple_triangle': 10.3,
    'baguette': 2.9,
    'bread_party': 2.9,
    'bread_ciabatta': 2.9,
    'baguette_oven': 2.9,
    'rod_chicken': 2.9,
    'roll_sunday': 2.9,
    'donut_whole_milk': 2.9,
    'humus_natural': 2.9,
    'berliner_vanilla': 2.9,
    'berliner': 2.9,
    'croissant': 2.9,
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        itemCount: items.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) => OrderCardWidget(
          itemId: items.entries.elementAt(index).key,
          price: items.entries.elementAt(index).value,
          onCountChanged: (count) {
            return true;
          },
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
          childAspectRatio: 1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
      ),
    );
  }
}
