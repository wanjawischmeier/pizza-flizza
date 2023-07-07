import 'dart:async';

import 'package:intl/intl.dart';
import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/item.dart';
import 'package:pizza_flizza/database/shop.dart';
import 'package:pizza_flizza/other/logger.util.dart';

import 'order.dart';
import 'orders.dart';

class OrderParser extends Orders {
  static final log = AppLogger();

  static void initializeUserGroupUpdates() {
    var user = Database.currentUser;
    if (user == null) {
      return;
    }

    onChildUpdated(event) {
      String updatedUserId = event.snapshot.key;
      Map? data = event.snapshot.value;
      if (data == null) {
        return;
      }

      parseOpenUserOrders(updatedUserId, data['orders']);
      parseUserFulfilledOrders(updatedUserId, data['fulfilled']);
      parseHistoryUserOrders(updatedUserId, data['history']);
      parseUserStats(updatedUserId, data['stats']);
    }

    onChildRemoved(event) {
      String updatedUserId = event.snapshot.key;
      Map? data = event.snapshot.value;
      if (data == null || data.isEmpty) {
        return;
      }

      Map? removedFulfilled = data['fulfilled'];
      if (removedFulfilled != null) {
        bool changed = false;
        for (Map fulfilledShop in removedFulfilled.values) {
          for (String userId in fulfilledShop.keys) {
            if (userId == user.userId) {
              Orders.fulfilled.remove(updatedUserId);
              changed = true;
            }
          }
        }

        if (changed) {
          Orders.fulfilledUpdatedController.add(Orders.fulfilled);
        }
      }

      if (data.containsKey('orders')) {
        Orders.orders.remove(updatedUserId);
        Orders.ordersUpdatedController.add(Orders.orders);
      }

      if (updatedUserId == user.userId && data.containsKey('history')) {
        Orders.history.clear();
        Orders.historyUpdatedController.add(Orders.history);
      }

      if (data.containsKey('stats')) {
        Orders.stats.remove(updatedUserId);
        Orders.statsUpdatedController.add(Orders.stats);
      }
    }

    var users = Database.realtime.child('users/${user.group.groupId}');
    Orders.groupDataAddedSubscription =
        users.onChildAdded.listen(onChildUpdated);
    Orders.groupDataChangedSubscription =
        users.onChildChanged.listen(onChildUpdated);
    Orders.groupDataRemovedSubscription =
        users.onChildRemoved.listen(onChildRemoved);
  }

  static Future<void> cancelUserGroupUpdates() async {
    await Orders.groupDataAddedSubscription?.cancel();
    await Orders.groupDataChangedSubscription?.cancel();
    await Orders.groupDataRemovedSubscription?.cancel();

    Orders.groupDataAddedSubscription = null;
    Orders.groupDataChangedSubscription = null;
    Orders.groupDataRemovedSubscription = null;
  }

  static Future<void> parseOpenUserOrders(
      String userId, Map? userOrders) async {
    // clear map in case of empty orders
    if (userOrders == null) {
      if (Orders.orders.containsKey(userId)) {
        Orders.orders.remove(userId);
        Orders.ordersUpdatedController.add(Orders.orders);
      }

      return;
    }

    bool modified = false;

    // initialize user orders entry
    if (Orders.orders.containsKey(userId)) {
      Orders.orders[userId]!.clear();
    } else {
      Orders.orders[userId] = {};
    }

    // iterate over all shops containing orders
    for (var shopEntry in userOrders.entries) {
      String shopId = shopEntry.key;
      String shopName = Shop.getShopName(shopId);
      Map shop = shopEntry.value;
      var items = <String, OrderItem>{};

      for (var itemEntry in shop.entries) {
        String itemId = itemEntry.key;
        Map item = itemEntry.value;

        // get item info
        var itemInfo = Shop.getItemInfo(shopId, itemId);
        String itemName = itemInfo['name'];
        int timestamp = item['timestamp'];
        int count = item['count'];
        double price = count * (itemInfo['price'] as double);

        // create instance
        var orderItem = OrderItem(
          itemId,
          shopId,
          userId,
          timestamp,
          itemName,
          shopName,
          count,
          price,
        );

        // compare to previous item
        var previousItem = Orders.orders[userId]?[shopId]?.items[itemId];
        if (orderItem != previousItem) {
          modified = true;
        }

        items[itemId] = orderItem;
      }

      Orders.orders[userId]?[shopId] = Order(
        shopId,
        shopName,
        items,
      );
      log.logOrderItems(items, userId, shopId, null);
    }

    // if orders changed: notify listeners
    if (modified) {
      Orders.ordersUpdatedController.add(Orders.orders);
    }
  }

  static Future<void> parseUserFulfilledOrders(
      String fulfillerId, Map? fulfilledOrders) async {
    var fulfillerName = Database.groupUsers[fulfillerId];
    if (fulfillerName == null) {
      return;
    }

    // clear map in case of empty orders
    if (fulfilledOrders == null) {
      if (Orders.fulfilled.containsKey(fulfillerId)) {
        Orders.fulfilled.remove(fulfillerId);
        Orders.fulfilledUpdatedController.add(Orders.fulfilled);
      }

      return;
    }

    bool modified = false;

    if (Orders.fulfilled.containsKey(fulfillerId)) {
      Orders.fulfilled[fulfillerId]?.clear();
    } else {
      Orders.fulfilled[fulfillerId] = {};
    }

    // iterate over all shops containing orders
    for (var shopEntry in fulfilledOrders.entries) {
      String shopId = shopEntry.key;
      String shopName = Shop.getShopName(shopId);
      Map fulfilledShop = shopEntry.value;

      if (!(Orders.fulfilled[fulfillerId]?.containsKey(shopId) ?? false)) {
        Orders.fulfilled[fulfillerId]?[shopId] = {};
      }

      for (var userEntry in fulfilledShop.entries) {
        String userId = userEntry.key;
        Map fulfilledItems = userEntry.value;
        var items = <String, OrderItem>{};

        for (var itemEntry in fulfilledItems.entries) {
          String itemId = itemEntry.key;
          Map item = itemEntry.value;

          // get item info
          var itemInfo = Shop.getItemInfo(shopId, itemId);
          String itemName = itemInfo['name'];
          int timestamp = item['timestamp'];
          int count = item['count'];
          double price = count * (itemInfo['price'] as double);

          // create instance
          var orderItem = OrderItem(
            itemId,
            shopId,
            userId,
            timestamp,
            itemName,
            shopName,
            count,
            price,
          );

          // compare to previous item
          var previousItem =
              Orders.fulfilled[fulfillerId]?[shopId]?[userId]?.items[itemId];
          if (orderItem != previousItem) {
            modified = true;
          }

          items[itemId] = orderItem;
        }

        var latestChange = 0;
        items.forEach((itemId, item) {
          if (item.timestamp > latestChange) {
            latestChange = item.timestamp;
          }
        });

        Orders.fulfilled[fulfillerId]?[shopId]?[userId] =
            FulfilledOrder.fromDate(
          fulfillerName,
          userId,
          shopId,
          shopName,
          DateTime.fromMillisecondsSinceEpoch(latestChange),
          items,
        );

        log.logOrderItems(items, userId, shopId, fulfillerId);
      }
    }

    // if orders changed: notify listeners
    if (modified) {
      Orders.fulfilledUpdatedController.add(Orders.fulfilled);
    }
  }

  static void parseHistoryUserOrders(String userId, Map? historyOrders) {
    // clear map in case of empty orders
    if (historyOrders == null) {
      if (Orders.history.containsKey(userId)) {
        Orders.history.remove(userId);
        Orders.historyUpdatedController.add(Orders.history);
      }

      return;
    }

    bool modified = false;

    if (Orders.history.containsKey(userId)) {
      Orders.history[userId]!.clear();
    } else {
      Orders.history[userId] = {};
    }

    // iterate over all shops containing a history
    for (var shopEntry in historyOrders.entries) {
      String shopId = shopEntry.key;
      String shopName = Shop.getShopName(shopId);
      Map shop = shopEntry.value;

      if (!(Orders.history[userId]?.containsKey(shopId) ?? false)) {
        Orders.history[userId]?[shopId] = {};
      }

      for (var ordersShop in shop.entries) {
        int timestamp = int.parse(ordersShop.key);
        DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        Map order = ordersShop.value;
        var items = <String, HistoryItem>{};

        for (var itemEntry in order.entries) {
          String itemId = itemEntry.key;
          int count = itemEntry.value;

          // get item info
          var itemInfo = Shop.getItemInfo(shopId, itemId);
          String itemName = itemInfo['name'];
          double price = count * (itemInfo['price'] as double);

          // compare to previous item
          var previousCount =
              Orders.history[userId]?[shopId]?[timestamp]?.items[itemId]?.count;
          if (count != previousCount) {
            modified = true;
          }

          items[itemId] = HistoryItem(
            itemName,
            count,
            price,
          );
        }

        Orders.history[userId]?[shopId]?[timestamp] = HistoryOrder(
          shopId,
          shopName,
          DateFormat.Hm().format(date),
          DateFormat('dd.MM.yy').format(date),
          items,
        );
        log.logHistoryOrderItems(items, userId, shopId);
      }
    }

    // if orders changed: notify listeners
    if (modified) {
      Orders.historyUpdatedController.add(Orders.history);
    }
  }

  static void parseUserStats(String userId, Map? stats) {
    // clear map in case of empty orders
    if (stats == null) {
      if (Orders.stats.containsKey(userId)) {
        Orders.stats.remove(userId);
        Orders.statsUpdatedController.add(Orders.stats);
      }

      return;
    }

    bool modified = false;

    if (Orders.stats.containsKey(userId)) {
      Orders.stats[userId]!.clear();
    } else {
      Orders.stats[userId] = {};
    }

    // iterate over all shops containing stats
    for (var shopEntry in stats.entries) {
      String shopId = shopEntry.key;
      Map shop = shopEntry.value;
      bool shopModified = false;

      if (!(Orders.stats[userId]?.containsKey(shopId) ?? false)) {
        Orders.stats[userId]?[shopId] = {};
      }

      for (var itemEntry in shop.entries) {
        String itemId = itemEntry.key;
        int count = itemEntry.value;

        // compare to previous item
        var previousCount = Orders.stats[userId]?[shopId]?[itemId];
        if (count != previousCount) {
          modified = true;
          shopModified = true;
        }

        Orders.stats[userId]?[shopId]?[itemId] = count;
      }

      if (shopModified) {
        Shop.sortShopItems(shopId);
      }
    }

    // if orders changed: notify listeners
    if (modified) {
      Orders.statsUpdatedController.add(Orders.stats);
    }
  }
}
