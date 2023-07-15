import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/item.dart';
import 'package:pizza_flizza/database/orders/order_access.dart';
import 'package:pizza_flizza/database/orders/orders.dart';

import 'order.dart';

class OrderManager extends Orders {
  static void clearOrderData() {
    Orders.orders.clear();
    Orders.fulfilled.clear();
    Orders.history.clear();

    Orders.ordersUpdatedController.add(Orders.orders);
    Orders.fulfilledUpdatedController.add(Orders.fulfilled);
    Orders.historyUpdatedController.add(Orders.history);
  }

  static Future<void>? removeOrderItem(OrderItem item) {
    Orders.orders[item.userId]?[item.shopId]?.items.remove(item.itemId);
    Orders.ordersUpdatedController.add(Orders.orders);
    return item.databaseReference?.remove();
  }

  static Future<void>? removeUserOrders() {
    var userId = Database.currentUser?.userId;
    if (userId == null) {
      return null;
    }

    Orders.orders.remove(userId);
    Orders.ordersUpdatedController.add(Orders.orders);
    return Database.userReference?.child('orders').remove();
  }

  static Future<void>? archiveFulfilledOrder(FulfilledOrder order) {
    var user = Database.currentUser;
    if (user == null) {
      return null;
    }
    var futures = <Future>[];

    // remove from fulfilled
    Orders.fulfilled.removeOrder(order);
    var fulfilledFuture = order.databaseReference?.remove();
    if (fulfilledFuture != null) {
      futures.add(fulfilledFuture);
    }

    // find recent existing order
    HistoryOrder? existingOrder;
    Orders.history[order.userId]?[order.shopId]
        ?.forEach((timestamp, historyOrder) {
      if ((timestamp - order.timestamp).abs() < Duration.millisecondsPerHour) {
        order.date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        existingOrder = historyOrder;
      }
    });

    // add to history
    var historyOrder = HistoryOrder.fromFulfilledOrder(order);
    existingOrder?.items.forEach((existingItemId, existingItem) {
      var item = historyOrder.items[existingItemId];
      if (item == null) {
        historyOrder.items[existingItemId] = existingItem;
      } else {
        historyOrder.items[existingItemId]!.count += existingItem.count;
      }
    });

    var historyFuture = Database.realtime
        .child(
          'users/${user.group.groupId}/${order.userId}/history/${order.shopId}/${order.timestamp}',
        )
        .set(historyOrder.json);
    futures.add(historyFuture);

    Orders.fulfilledUpdatedController.add(Orders.fulfilled);
    Orders.historyUpdatedController.add(Orders.history);
    return Future.wait(futures);
  }

  static Future<void>? fulfillItem(
    OrderItem item,
    int count, {
    OrderItem? originalItem,
  }) {
    var fulfiller = Database.currentUser;
    if (fulfiller == null) {
      return null;
    }

    var futures = <Future>[];
    var date = DateTime.now();

    // update fulfilled, skip fulfilling own order
    if (item.userId == fulfiller.userId) {
      var newItem = OrderItem.from(item);
      newItem.count = count;

      archiveFulfilledOrder(
        FulfilledOrder.fromUserItem(
          fulfiller.userId,
          date,
          newItem,
        ),
      );
    } else {
      item = Orders.fulfilled.addItem(fulfiller.userId, item);

      Map map = {
        'count': item.count,
        'timestamp': date.millisecondsSinceEpoch,
      };

      if (originalItem != null) {
        map[originalItem.itemId] = count;
      }

      var reference = Database.userReference
          ?.child('fulfilled/${item.shopId}/${item.userId}/${item.itemId}');
      if (reference != null) {
        futures.add(reference.set(map));
      }
    }

    Orders.fulfilledUpdatedController.add(Orders.fulfilled);

    // update shop stats
    item.bought += count;
    futures.add(
      item.shopReference.child('bought').set(item.bought),
    );

    if (originalItem != null) {
      // this item is replacing another one & therefore shouldn't be present in the order database
      return Future.wait(futures);
    }

    // update orders
    if (item.count <= count) {
      Orders.orders.removeItem(item);

      var future = item.databaseReference?.remove();
      if (future != null) {
        futures.add(future);
      }
    } else if (originalItem == null) {
      item.count -= count;
      Orders.orders.setItem(item);

      var future = item.databaseReference?.child('count').set(item.count);
      if (future != null) {
        futures.add(future);
      }
    }

    Orders.ordersUpdatedController.add(Orders.orders);
    return Future.wait(futures);
  }

  static Future<void> clearUserHistory() async {
    Orders.history.clear();
    Orders.historyUpdatedController.add(Orders.history);
    return Database.userReference?.child('history').remove();
  }
}
