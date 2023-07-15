import 'dart:async';

import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/item.dart';
import 'package:pizza_flizza/database/orders/order_access.dart';
import 'package:pizza_flizza/database/shop.dart';
import 'package:pizza_flizza/other/logger.util.dart';

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

    var users = Database.realtime.child('users/${user.group.groupId}');
    Orders.groupDataAddedSubscription =
        users.onChildAdded.listen(onChildUpdated);
    Orders.groupDataChangedSubscription =
        users.onChildChanged.listen(onChildUpdated);
  }

  static Future<void> cancelUserGroupUpdates() async {
    await Orders.groupDataAddedSubscription?.cancel();
    await Orders.groupDataChangedSubscription?.cancel();

    Orders.groupDataAddedSubscription = null;
    Orders.groupDataChangedSubscription = null;
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

    // initialize user orders entry
    var previousOrders = Orders.orders.deepClone;
    Orders.orders.remove(userId);

    // iterate over all shops containing orders
    for (var shopEntry in userOrders.entries) {
      String shopId = shopEntry.key;
      Map shop = shopEntry.value;
      var items = <String, OrderItem>{};

      for (var itemEntry in shop.entries) {
        String itemId = itemEntry.key;
        Map item = itemEntry.value;

        // create instance
        var orderItem = OrderItem(
          itemId,
          shopId,
          userId,
          item['timestamp'],
          item['count'],
        );

        items[itemId] = orderItem;
      }

      Orders.orders.setItems(userId, shopId, items);
      Orders.orders.logOrder(userId, shopId);
    }

    // if orders changed: notify listeners
    if (Orders.orders != previousOrders) {
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
    Orders.fulfilled.remove(fulfillerId);

    // iterate over all shops containing orders
    for (var shopEntry in fulfilledOrders.entries) {
      String shopId = shopEntry.key;
      Map fulfilledShop = shopEntry.value;

      for (var userEntry in fulfilledShop.entries) {
        String userId = userEntry.key;
        Map fulfilledItems = userEntry.value;
        var items = <String, OrderItem>{};

        for (var itemEntry in fulfilledItems.entries) {
          String itemId = itemEntry.key;
          Map item = itemEntry.value;
          int timestamp = item['timestamp'];
          int count = item['count'];

          // create instance
          var orderItem = OrderItem(
            itemId,
            shopId,
            userId,
            timestamp,
            count,
          );

          // compare to previous item
          var previousItem = Orders.fulfilled.getItem(
            fulfillerId,
            shopId,
            userId,
            itemId,
          );
          if (orderItem != previousItem) {
            modified = true;
          }

          items[itemId] = orderItem;
        }

        Orders.fulfilled.setItems(fulfillerId, shopId, userId, items);
        Orders.fulfilled.logOrder(fulfillerId, shopId, userId);
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
    Orders.history[userId]?.clear();

    // iterate over all shops containing a history
    for (var shopEntry in historyOrders.entries) {
      String shopId = shopEntry.key;
      Map shop = shopEntry.value;

      for (var ordersEntry in shop.entries) {
        int timestamp = int.parse(ordersEntry.key);
        DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        Map shopOrder = ordersEntry.value;
        var items = <String, HistoryItem>{};

        for (var itemEntry in shopOrder.entries) {
          String itemId = itemEntry.key;
          int count = itemEntry.value;

          // get item info
          var itemInfo = ShopItemInfo(shopId, itemId);
          double price = count * itemInfo.price;

          // compare to previous item
          var previousItem = Orders.history.getItem(
            userId,
            shopId,
            timestamp,
            itemId,
          );
          if (count != previousItem?.count) {
            modified = true;
          }

          items[itemId] = HistoryItem(
            itemId,
            itemInfo.itemName,
            count,
            price,
          );
        }

        Orders.history.setItems(userId, shopId, date, items);
        Orders.history.logOrder(userId, shopId, timestamp);
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

    var userStats = Orders.stats[userId];
    if (userStats == null) {
      Orders.stats[userId] = {};
      userStats = Orders.stats[userId];
    } else {
      userStats.clear();
    }

    // iterate over all shops containing stats
    for (var shopEntry in stats.entries) {
      String shopId = shopEntry.key;
      Map shop = shopEntry.value;
      bool shopModified = false;

      var shopStats = userStats![shopId];
      if (shopStats == null) {
        userStats[shopId] = {};
        shopStats = userStats[shopId];
      }

      for (var categoryEntry in shop.entries) {
        String categoryId = categoryEntry.key;
        var category = categoryEntry.value;

        var categoryStats = shopStats![categoryId];
        if (categoryStats == null) {
          shopStats[categoryId] = {};
          categoryStats = shopStats[categoryId];
        }

        for (var itemEntry in category.entries) {
          String itemId = itemEntry.key;
          int count = itemEntry.value;

          // compare to previous item
          var previousCount = Orders.stats.getStat(
            userId,
            shopId,
            categoryId,
            itemId,
          );

          if (count != previousCount) {
            modified = true;
            shopModified = true;
          }

          categoryStats![itemId] = count;
        }

        var sorted = categoryStats!.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        shopStats[categoryId] = {
          for (var entry in sorted) entry.key: entry.value
        };
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
