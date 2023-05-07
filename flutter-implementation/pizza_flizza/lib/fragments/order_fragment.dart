import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:pizza_flizza/database.dart';
import 'package:pizza_flizza/theme.dart';
import 'package:pizza_flizza/widgets/order_bottom_bar.dart';
import 'package:pizza_flizza/widgets/order_card.dart';

class OrderFragment extends StatefulWidget {
  const OrderFragment({super.key});

  @override
  State<OrderFragment> createState() => _OrderFragmentState();
}

class _OrderFragmentState extends State<OrderFragment> {
  late StreamSubscription<String> _shopChangedSubscription;

  @override
  void initState() {
    super.initState();
    _shopChangedSubscription = Shop.subscribeToShopChanged((shopId) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _shopChangedSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // item list
        Expanded(
          child: CustomScrollView(
            slivers: List.generate(Shop.items.length, (index) {
              var category = Shop.items.entries.elementAt(index);
              var categoryName = category.value['0_name'];
              var categoryItems = Map.from(category.value);
              categoryItems.remove('0_name');

              return SliverStickyHeader(
                overlapsContent: false,
                header: Container(
                  color: Themes.grayDark.withOpacity(0.9),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          categoryName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Flexible(
                        fit: FlexFit.tight,
                        child: Divider(
                          color: Themes.grayMid,
                          thickness: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  itemCount: categoryItems.length,
                  itemBuilder: (context, index) {
                    var item = categoryItems.entries.elementAt(index);
                    String name = item.value['name'];
                    double price = item.value['price'];

                    return Padding(
                      padding: const EdgeInsets.all(4),
                      child: OrderCardWidget(
                        categoryId: category.key,
                        itemId: item.key,
                        name: name,
                        price: price,
                        onCountChanged: Shop.setCurrentOrderItemCount,
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ),
        const OrderBottomBar(),
      ],
    );
  }
}
