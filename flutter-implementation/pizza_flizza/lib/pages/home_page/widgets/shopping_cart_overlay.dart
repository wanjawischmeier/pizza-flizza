import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/item.dart';
import 'package:pizza_flizza/database/orders/order_manager.dart';
import 'package:pizza_flizza/database/orders/orders.dart';
import 'package:pizza_flizza/other/helper.dart';
import 'package:pizza_flizza/other/theme.dart';
import 'package:pizza_flizza/pages/home_page/transaction_fragment/widgets/transaction_card.dart';

typedef OnRemoveOverlay = void Function();

class ShoppingCartOverlay extends StatefulWidget {
  final OnRemoveOverlay onRemoveOverlay;

  const ShoppingCartOverlay({super.key, required this.onRemoveOverlay});

  @override
  State<ShoppingCartOverlay> createState() => _ShoppingCartOverlayState();
}

class _ShoppingCartOverlayState extends State<ShoppingCartOverlay> {
  late StreamSubscription<OrderMap> _ordersSubscription2;
  final _ordersUser = <int, OrderItem>{};
  double _totalPrice = 0;

  @override
  void initState() {
    super.initState();

    var user = Database.currentUser;
    if (user == null) {
      return;
    }

    _ordersSubscription2 = Orders.subscribeToOrdersUpdated((orders) {
      _ordersUser.clear();
      _totalPrice = 0;

      var ordersUserRaw = orders[user.userId];
      if (ordersUserRaw == null) {
        widget.onRemoveOverlay();
      } else {
        // loop through orders for all shops
        ordersUserRaw.forEach((shopId, order) {
          order.items.forEach((itemId, item) {
            // use hash to account for possible duplicate itemId's across shops
            _ordersUser[item.hashCode] = item;
            _totalPrice += item.price;
          });
        });

        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ordersSubscription2.cancel();
    super.dispose();
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
                        Flexible(
                          child: const Text(
                            'shopping_cart.header',
                            style: TextStyle(
                              fontSize: 24,
                              decoration: TextDecoration.none,
                            ),
                          ).tr(),
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
                        secondaryColor: Themes.cream,
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
                          if (item == null) {
                            return;
                          }

                          setState(() {
                            _ordersUser.remove(itemId);
                            if (_ordersUser.isEmpty) {
                              widget.onRemoveOverlay();
                            }

                            // max to avoid floating point -0.00 rounding error
                            _totalPrice = max(0, _totalPrice - item.price);
                          });

                          OrderManager.removeOrderItem(item);
                        },
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Themes.cream,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: widget.onRemoveOverlay,
                  child: const Text(
                    'shopping_cart.close',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ).tr(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
