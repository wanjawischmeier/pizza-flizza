import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/item.dart';
import 'package:pizza_flizza/database/order.dart';
import 'package:pizza_flizza/database/shop.dart';
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
  late StreamSubscription<OrderMap> _ordersSubscription2;
  final _ordersUser = <int, OrderItem2>{};
  double _totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _ordersSubscription2 = Shop.subscribeToOrdersUpdated2((orders) {
      _ordersUser.clear();
      _totalPrice = 0;

      // loop through orders for all shops
      orders[Database.userId]?.forEach((shopId, order) {
        order.items.forEach((itemId, item) {
          // use hash to account for possible duplicate itemId's across shops
          _ordersUser[item.hashCode] = item;
          _totalPrice += item.price;
        });
      });

      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _ordersSubscription2.cancel();
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
                              Helper.formatPrice(_totalPrice),
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
                    itemCount: _ordersUser.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      var entry = _ordersUser.entries.elementAt(index);
                      var itemId = entry.key, item = entry.value;

                      return TransactionCardWidget(
                        backgroundColor: Themes.grayLight,
                        accentColor: Themes.cream,
                        id: itemId,
                        header: '${item.count}x\t${item.itemName}',
                        content: item.shopName,
                        trailing: Helper.formatPrice(item.price),
                        icon: const Icon(Icons.delete),
                        dismissable: true,
                        onDismiss: (id) {
                          var itemId = id as int;
                          var item = _ordersUser[itemId];

                          setState(() {
                            // _orders.remove(item);
                            _ordersUser.remove(itemId);

                            // max to avoid floating point -0.00 rounding error
                            _totalPrice = max(
                              0,
                              _totalPrice - (item?.price ?? 0),
                            );
                          });

                          // Shop.removeItem(item);
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
