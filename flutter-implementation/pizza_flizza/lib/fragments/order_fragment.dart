import 'package:cached_firestorage/remote_picture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:intl/intl.dart';
import 'package:pizza_flizza/database.dart';
import 'package:pizza_flizza/theme.dart';
import 'package:pizza_flizza/widgets/order_card.dart';

class OrderFragment extends StatefulWidget {
  const OrderFragment({super.key});

  @override
  State<OrderFragment> createState() => _OrderFragmentState();
}

class _OrderFragmentState extends State<OrderFragment> {
  Map<String, List<OrderCardWidget>> map = {};
  double _currentTotal = 0;

  @override
  void initState() {
    super.initState();
    Shop.onChanged = () => setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                  children: List.generate(categoryItems.length, (itemIndex) {
                    var item = categoryItems.entries.elementAt(itemIndex);
                    String name = item.value['name'];
                    double price = item.value['price'];

                    return Padding(
                      padding: const EdgeInsets.all(4),
                      child: OrderCardWidget(
                        categoryId: category.key,
                        itemId: item.key,
                        name: name,
                        price: price,
                        onCountChanged: (categoryId, itemId, count) {
                          setState(() {
                            _currentTotal += count *
                                Shop.items[categoryId]?[itemId]?['price'];
                          });
                          return true;
                        },
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Themes.grayDark,
            borderRadius:
                BorderRadiusDirectional.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: Themes.grayMid,
                spreadRadius: 2,
                blurRadius: 4,
              )
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('list'),
                  Container(
                    decoration: BoxDecoration(
                      color: Themes.grayLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Center(
                      child: Text(
                        NumberFormat.simpleCurrency(
                          locale:
                              'de_DE', // Localizations.localeOf(context).scriptCode,
                        ).format(_currentTotal),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Shop.pushOrder({
                      'hearty': {'baguette': 2}
                    });
                    setState(() {});
                  },
                  child: const Text('Order'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
