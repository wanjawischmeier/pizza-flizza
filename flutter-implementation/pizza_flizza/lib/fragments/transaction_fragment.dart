import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/order.dart';
import 'package:pizza_flizza/database/shop.dart';
import 'package:pizza_flizza/helper.dart';
import 'package:pizza_flizza/theme.dart';
import 'package:pizza_flizza/widgets/transaction_card.dart';

class TransactionFragment extends StatefulWidget {
  const TransactionFragment({super.key});

  @override
  State<TransactionFragment> createState() => _TransactionFragmentState();
}

class _TransactionFragmentState extends State<TransactionFragment> {
  late StreamSubscription<FulfilledMap> _fulfilledSubscription;
  late StreamSubscription<HistoryMap> _historySubscription;
  final _fulfilledRelevant = <int, FulfilledOrder2>{};
  final _historyUser = <int, FulfilledOrder2>{};

  Future<void> filterOrder(
      String fulfillerId, String userId, Order2 order) async {
    // order is relevant if fulfilled or ordered by user
    if (fulfillerId == Database.userId || userId == Database.userId) {
      int latestChange = 0;

      order.items.forEach((itemId, item) {
        if (item.timestamp > latestChange) {
          latestChange = item.timestamp;
        }
      });
      var date = DateTime.fromMillisecondsSinceEpoch(latestChange);

      String fulfillerName = 'Unknown Fulfiller';
      String userName = 'Unknown User';
      String? currentUserName = Database.userName;
      Future<void> future;

      if (fulfillerId == Database.userId && currentUserName != null) {
        // if the user is
        fulfillerName = currentUserName;
        future = Database.getUserName(userId).then((name) {
          userName = name;
        });
      } else if (currentUserName != null) {
        // userId being Database.userId is implied
        future = Database.getUserName(fulfillerId).then((name) {
          fulfillerName = name;
        });
        userName = currentUserName;
      } else {
        var fulfillerFuture = Database.getUserName(fulfillerId).then((name) {
          fulfillerName = name;
        });
        var userFuture = Database.getUserName(userId).then((name) {
          userName = name;
        });
        future = Future.wait([fulfillerFuture, userFuture]);
      }

      return future.then((value) {
        // use hash to account for possible duplicate itemId's
        _fulfilledRelevant[order.hashCode] = FulfilledOrder2(
          fulfillerId,
          userId,
          order.shopId,
          fulfillerName,
          userName,
          DateFormat.Hm().format(date),
          DateFormat('dd.MM.yy').format(date),
          order.items,
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _fulfilledSubscription = Shop.subscribeToFulfilledUpdated2((orders) async {
      var futures = <Future>[];

      orders.forEach((fulfillerId, ordersFulfiller) {
        ordersFulfiller.forEach((shopId, ordersShop) {
          ordersShop.forEach((userId, order) {
            futures.add(filterOrder(fulfillerId, userId, order));
          });
        });
      });

      // await potential usernames being gathered
      await Future.wait(futures);
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();

    _fulfilledSubscription.cancel();
    _historySubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: _fulfilledRelevant.length,
      padding: const EdgeInsets.all(8),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        var orderEntry = _fulfilledRelevant.entries.elementAt(index);
        var timestamp = orderEntry.key, order = orderEntry.value;
        bool dismissable;
        Color color;
        String credit;
        IconData? iconData;

        if (order.fulfillerId == Database.userId) {
          // order fulfilled by user
          dismissable = true;
          color = Themes.cream;
          credit = order.userName;
          iconData = Icons.check;
        } else {
          // order placed by user
          color = Themes.grayLight;
          dismissable = false;
          credit = order.fulfillerName;
        }

        return TransactionCardWidget(
          backgroundColor: Themes.grayMid,
          accentColor: color,
          id: timestamp,
          header:
              'Bought for $credit\n${order.timeFormatted} on ${order.dateFormatted}',
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

              Shop.archiveFulfilledOrder(order);
            }
          },
        );
      },
    );
  }
}
