import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/orders/order.dart';
import 'package:pizza_flizza/database/orders/order_manager.dart';
import 'package:pizza_flizza/database/orders/orders.dart';
import 'package:pizza_flizza/other/helper.dart';
import 'package:pizza_flizza/other/theme.dart';
import 'package:pizza_flizza/pages/home_page/transaction_fragment/widgets/transaction_card.dart';

class TransactionFragment extends StatefulWidget {
  const TransactionFragment({super.key});

  @override
  State<TransactionFragment> createState() => _TransactionFragmentState();
}

class _TransactionFragmentState extends State<TransactionFragment> {
  late StreamSubscription<FulfilledMap> _fulfilledSubscription;
  late StreamSubscription<HistoryMap> _historySubscription;
  var _fulfilledRelevant = <int, FulfilledOrder>{};
  var _historyUser = <int, HistoryOrder>{};
  final _futures = <Future>[];

  TransactionCardWidget renderFulfilledOrderAt(int index) {
    var orderEntry = _fulfilledRelevant.entries.elementAt(index);
    var timestamp = orderEntry.key, order = orderEntry.value;
    bool dismissable;
    Color color;
    String messageTemplate, credit;
    IconData? iconData;

    var user = Database.currentUser;
    if (user == null) {
      throw Exception('User undefined');
    }

    if (order.fulfillerId == user.userId) {
      // order fulfilled by user
      dismissable = true;
      color = Themes.cream;
      messageTemplate = 'transaction.bought_for';
      credit = Database.getUserName(order.userId) ??
          'database.unknown_username'.tr();
      iconData = Icons.check;
    } else {
      // order placed by user
      color = Themes.grayLight;
      dismissable = false;
      messageTemplate = 'transaction.bought_by';
      credit = Database.getUserName(order.fulfillerId) ??
          'database.unknown_username'.tr();
    }

    return TransactionCardWidget(
      backgroundColor: Themes.grayMid,
      secondaryColor: color,
      accentColor: color,
      id: timestamp,
      header: messageTemplate.tr(args: [credit]),
      subHeader: 'transaction.date_location'.tr(
        args: [order.timeFormatted, order.dateFormatted, order.shopName],
      ),
      content: order.itemsFormatted,
      trailing: Helper.formatPrice(order.price),
      icon: Icon(iconData),
      dismissable: dismissable,
      onDismiss: (orderId) {
        var order = _fulfilledRelevant[orderId];
        if (order != null) {
          setState(() {
            _fulfilledRelevant.remove(orderId);
          });

          OrderManager.archiveFulfilledOrder(order);
        }
      },
    );
  }

  TransactionCardWidget renderHistoryOrderAt(int index) {
    var orderEntry = _historyUser.entries.elementAt(index);
    var timestamp = orderEntry.key, order = orderEntry.value;

    return TransactionCardWidget(
      backgroundColor: Themes.grayMid,
      secondaryColor: Themes.grayLight,
      accentColor: Themes.grayMid,
      id: timestamp,
      header: 'transaction.date'.tr(
        args: [order.timeFormatted, order.dateFormatted],
      ),
      subHeader: order.shopName,
      content: order.itemsFormatted,
      trailing: Helper.formatPrice(order.price),
      dismissable: false,
    );
  }

  @override
  void initState() {
    super.initState();

    var user = Database.currentUser;
    if (user == null) {
      return;
    }

    _fulfilledSubscription = Orders.subscribeToFulfilledUpdated((orders) async {
      // already gathering info on state, discard update
      if (_futures.isNotEmpty) {
        return;
      }

      _fulfilledRelevant.clear();

      orders.forEach((fulfillerId, ordersFulfiller) {
        ordersFulfiller.forEach((shopId, ordersShop) {
          ordersShop.forEach((userId, order) {
            // order is relevant if fulfilled or ordered by user
            if (fulfillerId == user.userId || userId == user.userId) {
              _fulfilledRelevant[order.hashCode] = order;
            }
          });
        });
      });

      // await potential usernames being gathered
      await Future.wait(_futures);
      _futures.clear();

      setState(() {
        _fulfilledRelevant = Helper.sortByHighestKey(_fulfilledRelevant);
      });
    });

    _historySubscription = Orders.subscribeToHistoryUpdated((orders) {
      _historyUser.clear();

      orders[user.userId]?.forEach((shopId, ordersShop) {
        ordersShop.forEach((timestamp, order) {
          _historyUser[timestamp] = order;
        });
      });

      setState(() {
        _historyUser = Helper.sortByHighestKey(_historyUser);
      });
    });
  }

  @override
  void dispose() {
    _fulfilledSubscription.cancel();
    _historySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_fulfilledRelevant.isEmpty && _historyUser.isEmpty) {
      return Center(
        child: Container(
          decoration: BoxDecoration(
            color: Themes.grayMid,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: const Text(
            'transaction.no_transactions',
            style: TextStyle(fontSize: 24),
          ).tr(),
        ),
      );
    }

    return ListView.separated(
      itemCount: _fulfilledRelevant.length + _historyUser.length + 1,
      padding: const EdgeInsets.all(8),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        if (index < _fulfilledRelevant.length) {
          return renderFulfilledOrderAt(index);
        } else if (index < _fulfilledRelevant.length + _historyUser.length) {
          return renderHistoryOrderAt(index - _fulfilledRelevant.length);
        } else if (_historyUser.isNotEmpty) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Themes.grayMid,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              _historyUser.clear();
              OrderManager.clearUserHistory();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'transaction.clear_history',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
              ).tr(),
            ),
          );
        } else {
          return null;
        }
      },
    );
  }
}
