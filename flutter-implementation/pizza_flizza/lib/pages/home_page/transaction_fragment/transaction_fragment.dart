import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/order.dart';
import 'package:pizza_flizza/database/shop.dart';
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

  Future<void> filterOrder(
      String fulfillerId, String userId, Order order) async {
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
      Future<void> future;

      if (fulfillerId == Database.userId && Database.userName != null) {
        // if the user is
        fulfillerName = Database.userName!;
        future = Database.getUserName(userId).then((name) {
          userName = name;
        });
      } else if (Database.userName != null) {
        // userId being Database.userId is implied
        future = Database.getUserName(fulfillerId).then((name) {
          fulfillerName = name;
        });
        userName = Database.userName!;
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
        _fulfilledRelevant[order.hashCode] = FulfilledOrder(
          fulfillerId,
          userId,
          order.shopId,
          order.shopName,
          fulfillerName,
          userName,
          DateFormat.Hm().format(date),
          DateFormat('dd.MM.yy').format(date),
          order.items,
        );
      });
    }
  }

  TransactionCardWidget renderFulfilledOrderAt(int index) {
    var orderEntry = _fulfilledRelevant.entries.elementAt(index);
    var timestamp = orderEntry.key, order = orderEntry.value;
    bool dismissable;
    Color color;
    String preposition, credit;
    IconData? iconData;

    if (order.fulfillerId == Database.userId) {
      // order fulfilled by user
      dismissable = true;
      color = Themes.cream;
      preposition = 'for';
      credit = order.userName;
      iconData = Icons.check;
    } else {
      // order placed by user
      color = Themes.grayLight;
      dismissable = false;
      preposition = 'by';
      credit = order.fulfillerName;
    }

    return TransactionCardWidget(
      backgroundColor: Themes.grayMid,
      accentColor: color,
      id: timestamp,
      header: 'Bought $preposition $credit',
      subHeader:
          '${order.timeFormatted} on ${order.dateFormatted} at ${order.shopName}',
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
  }

  TransactionCardWidget renderHistoryOrderAt(int index) {
    var orderEntry = _historyUser.entries.elementAt(index);
    var timestamp = orderEntry.key, order = orderEntry.value;

    return TransactionCardWidget(
      backgroundColor: Themes.grayMid,
      accentColor: Themes.grayMid,
      id: timestamp,
      header:
          '${order.timeFormatted} on ${order.dateFormatted}\nat ${order.shopName}',
      content: order.itemsFormatted,
      trailing: Helper.formatPrice(order.price),
      dismissable: false,
    );
  }

  @override
  void initState() {
    super.initState();

    _fulfilledSubscription = Shop.subscribeToFulfilledUpdated((orders) async {
      // already gathering info on state, discard update
      if (_futures.isNotEmpty) {
        return;
      }

      _fulfilledRelevant.clear();

      orders.forEach((fulfillerId, ordersFulfiller) {
        ordersFulfiller.forEach((shopId, ordersShop) {
          ordersShop.forEach((userId, order) {
            _futures.add(filterOrder(fulfillerId, userId, order));
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

    _historySubscription = Shop.subscribeToHistoryUpdated((orders) {
      _historyUser.clear();

      orders[Database.userId]?.forEach((shopId, ordersShop) {
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
            'No Transactions',
            style: TextStyle(fontSize: 24),
          ),
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
              Shop.clearUserHistory();
            },
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Clear History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
              ),
            ),
          );
        } else {
          return null;
        }
      },
    );
  }
}
