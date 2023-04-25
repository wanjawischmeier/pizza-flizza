import 'package:flutter/material.dart';
import 'package:pizza_flizza/theme.dart';
import 'package:pizza_flizza/widgets/order_card.dart';
import 'package:sticky_headers/sticky_headers.dart';

class OrderFragment extends StatelessWidget {
  const OrderFragment({super.key});

  static const Map<String, Map<String, double>> items =
      <String, Map<String, double>>{
    'hearty': {
      'pizza': 1.2,
      'baguette': 2.9,
      'bread_party': 2.9,
      'bread_ciabatta': 2.9,
      'baguette_oven': 2.9,
      'rod_chicken': 2.9,
      'roll_sunday': 2.9,
    },
    'sweet': {
      'apple_triangle': 10.3,
      'donut_whole_milk': 2.9,
      'humus_natural': 2.9,
      'berliner_vanilla': 2.9,
      'berliner': 2.9,
      'croissant': 2.9,
    },
    'dips': {
      'baguette': 2.9,
      'bread_party': 2.9,
      'bread_ciabatta': 2.9,
      'humus_natural': 2.9,
      'berliner_vanilla': 2.9,
      'berliner': 2.9,
    },
  };

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        var category = items.entries.elementAt(index);
        var categoryName = category.key;
        var categoryItems = category.value.entries;

        return StickyHeader(
          header: Container(
            color: Themes.grayDark.withOpacity(0.9),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(categoryName),
                ),
                const Flexible(
                    fit: FlexFit.tight,
                    child: Divider(
                      color: Themes.grayMid,
                      thickness: 2,
                    )),
              ],
            ),
          ),
          content: LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: categoryItems.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) => OrderCardWidget(
                itemId: categoryItems.elementAt(index).key,
                price: categoryItems.elementAt(index).value,
                onCountChanged: (count) {
                  return true;
                },
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: (constraints.maxWidth / 225).round(),
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
            ),
          ),
        );
      },
    );
  }
}
