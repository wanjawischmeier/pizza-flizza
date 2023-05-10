import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pizza_flizza/database.dart';
import 'package:pizza_flizza/theme.dart';
import 'package:pizza_flizza/widgets/transaction_card.dart';

typedef OnRemoveOverlay = void Function();

class CartItem {
  String shopId, id;
  int count;

  CartItem(
    this.shopId,
    this.id,
    this.count,
  );
}

class ShoppingCart extends StatefulWidget {
  final OnRemoveOverlay onRemoveOverlay;

  const ShoppingCart({super.key, required this.onRemoveOverlay});

  @override
  State<ShoppingCart> createState() => _ShoppingCartState();
}

class _ShoppingCartState extends State<ShoppingCart> {
  late StreamSubscription<Map<String, Map>> _openOrdersSubscription;
  var _allOrders = <CartItem>[];
  set rawOrders(Map<String, Map> value) {
    var orders = <CartItem>[];

    value.forEach((shopId, order) {
      order.forEach((itemId, count) {
        orders.add(CartItem(shopId, itemId, count));
      });
    });

    _allOrders = orders;
  }

  @override
  void initState() {
    super.initState();
    _openOrdersSubscription = Shop.subscribeToOrderUpdated((orders) {
      setState(() {
        rawOrders = orders;
      });
    });
    rawOrders = Shop.openOrders;
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
                            'Your Orders',
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
                              'total',
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
                    itemCount: _allOrders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      var item = _allOrders[index];
                      String name = Shop.getItemName(item.id);
                      String shopName = Shop.shopName;

                      return TransactionCardWidget(
                        backgroundColor: Themes.grayLight,
                        accentColor: Themes.cream,
                        id: item,
                        header: '${item.count}x\t$name',
                        content: shopName,
                        trailing: '9.99 §',
                        icon: const Icon(Icons.delete),
                        dismissable: true,
                        onDismiss: (id) {
                          var item = id as CartItem;

                          setState(() {
                            _allOrders.remove(item);
                          });

                          Shop.removeItemFromOrders(item.shopId, item.id);
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
