import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/item.dart';
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
    Orders.fulfilled[order.fulfillerId]?[order.shopId]?.remove(order.userId);
    // clean map propagating up the tree
    if (Orders.fulfilled[order.fulfillerId]?[order.shopId]?.isEmpty ?? false) {
      Orders.fulfilled[order.fulfillerId]?.remove(order.shopId);

      if (Orders.fulfilled[order.fulfillerId]?.isEmpty ?? false) {
        Orders.fulfilled.clear();
      }
    }
    var fulfilledFuture = order.databaseReference?.remove();
    if (fulfilledFuture != null) {
      futures.add(fulfilledFuture);
    }

    HistoryOrder? existingOrder;
    Orders.history[order.userId]?[order.shopId]
        ?.forEach((timestamp, historyOrder) {
      // find recent existing order
      if ((timestamp - order.timestamp).abs() < Duration.millisecondsPerHour) {
        order.timestamp = timestamp;
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
            'users/${user.group.groupId}/${order.userId}/history/${order.shopId}/${order.timestamp}')
        .set(historyOrder.itemsParsed);
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
          newItem,
          fulfiller.userId,
          date,
        ),
      );
    } else {
      int fulfilledCount = Orders
              .fulfilled[fulfiller.userId]?[item.shopId]?[item.userId]
              ?.items[item.itemId]
              ?.count ??
          0;

      var fulfilledOrder = FulfilledOrder.fromDate(
        fulfiller.userId,
        item.userId,
        item.shopId,
        item.shopName,
        date,
        {item.itemId: OrderItem.from(item)},
      );

      if (Orders.fulfilled.containsKey(fulfiller.userId)) {
        if (Orders.fulfilled[fulfiller.userId]!.containsKey(item.shopId)) {
          if (Orders.fulfilled[fulfiller.userId]![item.shopId]!
              .containsKey(item.userId)) {
            Orders.fulfilled[fulfiller.userId]![item.shopId]![item.userId]!
                .items[item.itemId] = OrderItem.from(item);
          } else {
            Orders.fulfilled[fulfiller.userId]![item.shopId]![item.userId] =
                fulfilledOrder;
          }
        } else {
          Orders.fulfilled[fulfiller.userId]![item.shopId] = {
            item.userId: fulfilledOrder,
          };
        }
      } else {
        Orders.fulfilled[fulfiller.userId] = {
          item.shopId: {
            item.userId: fulfilledOrder,
          }
        };
      }

      var fulfilledItem = Orders
              .fulfilled[fulfiller.userId]![item.shopId]![item.userId]!
              .items[item.itemId] ??
          OrderItem.from(item);
      fulfilledItem.count = fulfilledCount + count;
      // TODO: update price!
      fulfilledItem.price = -1;

      Map map = {
        'count': fulfilledCount + count,
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
    item.shopInfo.bought += count;
    futures.add(
      item.shopReference.child('bought').set(item.shopInfo.bought),
    );

    if (originalItem != null) {
      // this item is replacing another one & therefore shouldn't be present in the order database
      return Future.wait(futures);
    }

    // update orders
    if (item.count <= count) {
      Orders.orders[item.userId]?[item.shopId]?.items.remove(item.itemId);
      var future = item.databaseReference?.remove();
      if (future != null) {
        futures.add(future);
      }
    } else if (originalItem == null) {
      item.count -= count;
      Orders.orders[item.userId]?[item.shopId]?.items[item.itemId]?.count =
          item.count;
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
