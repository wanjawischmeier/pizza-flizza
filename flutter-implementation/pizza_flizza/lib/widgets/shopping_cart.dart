import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pizza_flizza/database.dart';
import 'package:pizza_flizza/helper.dart';
import 'package:pizza_flizza/theme.dart';
import 'package:pizza_flizza/widgets/transaction_card.dart';

typedef OnRemoveOverlay = void Function();

class ShoppingCart extends StatefulWidget {
  final OnRemoveOverlay onRemoveOverlay;

  const ShoppingCart({super.key, required this.onRemoveOverlay});

  @override
  State<ShoppingCart> createState() => _ShoppingCartState();
}

class _ShoppingCartState extends State<ShoppingCart> {
  late StreamSubscription<List<ShopItem>> _openOrdersSubscription;
  var _orders = <ShopItem>[];

  List<ShopItem> filterOrders(List<ShopItem> orders) {
    return orders.where((order) {
      return order.userId == Database.userId;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _openOrdersSubscription = Shop.subscribeToOrderUpdated((orders) {
      setState(() {
        _orders = filterOrders(orders);
      });
    });
    _orders = filterOrders(Shop.openOrders);
  }

  @override
  void dispose() {
    super.dispose();
    _openOrdersSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: Themes.grayMid,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                  bottom: Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'Your Order',
                            style: TextStyle(
                              fontSize: 24,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Themes.cream,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: Text(
                              Helper.formatPrice(Shop.openTotal),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    itemCount: _orders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      var item = _orders[index];

                      return TransactionCardWidget(
                        backgroundColor: Themes.grayLight,
                        accentColor: Themes.cream,
                        id: item,
                        header: '${item.count}x\t${item.name}',
                        content: item.shopName,
                        trailing: Helper.formatPrice(item.price),
                        icon: const Icon(Icons.delete),
                        dismissable: true,
                        onDismiss: (id) {
                          var item = id as ShopItem;

                          setState(() {
                            _orders.remove(item);
                          });

                          Shop.removeItem(item);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
