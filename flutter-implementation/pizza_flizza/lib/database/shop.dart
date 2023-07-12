import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pizza_flizza/database/orders/orders.dart';
import 'package:pizza_flizza/other/helper.dart';
import 'package:pizza_flizza/other/logger.util.dart';

import 'database.dart';
import 'item.dart';
import 'orders/order.dart';

class Shop {
  static final log = AppLogger();

  // shop database
  static late String _currentShopId;
  static String get currentShopId => _currentShopId;
  static set currentShopId(String newShopId) {
    if (newShopId == _currentShopId) {
      return;
    }

    _currentShopId = newShopId;
    _currentOrder.clear();
    _currentTotal = 0;

    shopChangedController.add(_currentShopId);
  }

  static String get currentShopName => getShopName(_currentShopId);

  // TODO: properly parse items
  static Map<dynamic, dynamic> shops = {};
  static Map<String, Map<String, int>> stats = {};
  static Map<dynamic, dynamic> get items {
    return shops[_currentShopId]['items'];
  }

  static String getShopName(String shopId) {
    return shops[shopId]?['name'] ?? 'database.unknown_shop'.tr();
  }

  static Map getItemInfo(String shopId, String itemId) {
    for (var categoryEntry in shops[shopId]?['items']?.entries ?? {}) {
      String categoryId = categoryEntry.key;
      var category = categoryEntry.value;

      for (var itemEntry in category.entries) {
        if (itemEntry.key == itemId) {
          itemEntry.value['categoryId'] = categoryId;
          return itemEntry.value;
        }
      }
    }

    return {
      'name': 'database.unknown_item_name'.tr(),
      'category': 'unknown_category_id',
      'price': 0.0,
      'bought': 0,
    };
  }

  static final StreamController<String> shopChangedController =
      StreamController.broadcast();
  static StreamSubscription<String> subscribeToShopChanged(
      void Function(String shopId) onUpdate) {
    onUpdate(_currentShopId);
    return shopChangedController.stream.listen(onUpdate);
  }

  // shopId, itemId -> count
  static final Map<String, int> _currentOrder = {};
  static Map<String, int> get currentOrder => _currentOrder;
  static String get currentOrderString {
    String result = '';

    for (var item in _currentOrder.entries) {
      result +=
          '- ${item.value}x\t${getItemInfo(_currentShopId, item.key)['name']}\n';
    }

    return result.substring(0, max(0, result.length - 1));
  }

  static double _currentTotal = 0;
  static final StreamController<double> currentTotalController =
      StreamController.broadcast();
  static StreamSubscription<double> subscribeToCurrentTotal(
      void Function(double total) onUpdate) {
    onUpdate(_currentTotal);
    return currentTotalController.stream.listen(onUpdate);
  }

  static void clearCurrentOrder() {
    _currentOrder.clear();
    _currentTotal = 0;
    currentTotalController.add(_currentTotal);
  }

  static final Map<String, List<Reference>> _itemReferences = {};

  static Future<void> initializeShops() async {
    var snapshot = await Database.realtime.child('shops').get();
    shops = snapshot.value as Map;
    _currentShopId = shops.keys.first;

    for (var shopEntry in shops.entries) {
      String shopId = shopEntry.key;
      var shop = shopEntry.value;

      // list product images for the shop
      var imagesSnapshot = await Database.storage
          .child(
            'images/${Database.imageResolution}/shops/$shopId/items',
          )
          .listAll();
      _itemReferences[shopId] = imagesSnapshot.items;

      // parse global item stats
      for (var categoryEntry in shop['items'].entries) {
        String categoryId = categoryEntry.key;
        var category = categoryEntry.value;

        if (!stats.containsKey(categoryId)) {
          stats[categoryId] = {};
        }

        for (var itemEntry in category.entries) {
          String itemId = itemEntry.key;
          if (itemId == '0_name') {
            continue;
          }

          int? bought = itemEntry.value['bought'];
          if (bought != null) {
            stats[categoryId]![itemId] = bought;
          }
        }

        stats[categoryId] = Helper.sortByHighestValue(stats[categoryId]!);
      }

      sortShopItems(shopId);
    }
  }

  static bool sortShopItems(String shopId) {
    bool modified = false;

    for (var categoryEntry in shops[currentShopId]['items'].entries) {
      String categoryId = categoryEntry.key;
      var categoryStats = Orders.userStats?[currentShopId]?[categoryId];

      var sorted = Helper.sortByComparator(categoryEntry.value, (item0, item1) {
        int bought0, bought1;
        int stat0 = (categoryStats?[item0.key] ?? 0) * 10000;
        int stat1 = (categoryStats?[item1.key] ?? 0) * 10000;

        if (item0.key == '0_name') {
          bought0 = 0;
        } else if (stat0 != 0) {
          bought0 = stat0;
        } else {
          bought0 = (item0.value as Map)['bought'];
        }

        if (item1.key == '0_name') {
          bought1 = 0;
        } else if (stat1 != 0) {
          bought1 = stat1;
        } else {
          bought1 = (item1.value as Map)['bought'];
        }

        if (bought0 == bought1) {
          return 0;
        } else {
          return bought0 < bought1 ? 1 : -1;
        }
      });

      if (sorted != categoryEntry.value) {
        shops[currentShopId]['items'][categoryEntry.key] = sorted;
        modified = true;
      }
    }

    return modified;
  }

  static bool containsReference(String referencePath) {
    var reference = Database.storage.child(referencePath);
    return _itemReferences[_currentShopId]?.contains(reference) ?? false;
  }

  static void setCurrentOrderItemCount(
    String categoryId,
    String itemId,
    int count,
  ) {
    double price = items[categoryId]?[itemId]?['price'];
    int oldCount = _currentOrder[itemId] ?? 0;
    if (count == 0) {
      _currentOrder.remove(itemId);
    } else {
      _currentOrder[itemId] = count;
    }

    // number of added items times item price, also works for subtraction
    double rawTotal = _currentTotal + (count - oldCount) * price;
    // limit result
    _currentTotal = (rawTotal.abs() * 100).roundToDouble() / 100;
    currentTotalController.add(_currentTotal);
  }

  static Future<void>? pushCurrentOrder() {
    var user = Database.currentUser;
    if (user == null) {
      return null;
    }

    var futures = <Future>[];
    /*
    var ordersUser = Orders.orders[user.userId];
    if (ordersUser == null) {
      ordersUser = {
        _currentShopId: Order(
          _currentShopId,
          items,
        ),
      };
    } else {
      var ordersShop = ordersUser[_currentShopId];
      if (ordersShop == null) {
        ordersShop = Order(_currentShopId, items);
      } else {
        items = ordersShop.items;
      }
    }
    */

    // initialize with existing
    var items = Orders.orders.getOrder(user.userId, _currentShopId)?.items;
    items ??= {};
    var orderData = <String, Map<String, int>>{};
    for (var itemEntry in items.entries) {
      var itemId = itemEntry.key;
      var item = itemEntry.value;

      orderData[itemId] = <String, int>{
        'timestamp': item.timestamp,
        'count': item.count,
      };
    }

    // loop through current
    _currentOrder.forEach((itemId, count) {
      int timestamp = DateTime.now().millisecondsSinceEpoch;
      int newCount = count + (orderData[itemId]?['count'] ?? 0);

      orderData[itemId] = <String, int>{
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'count': newCount,
      };

      var item = OrderItem.loadShopItem(
        user.userId,
        _currentShopId,
        itemId,
        timestamp,
        newCount,
      );
      items![itemId] = item;

      // update stats
      int oldStat = Orders.stats[user.userId]?[_currentShopId]?[item.categoryId]
              ?[itemId] ??
          0;
      var future = Database.userReference
          ?.child('stats/$_currentShopId/${item.categoryId}/$itemId')
          .set(oldStat + count);
      if (future != null) {
        futures.add(future);
      }
    });

    var future =
        Database.userReference?.child('orders/$_currentShopId').set(orderData);

    _currentTotal = 0;
    _currentOrder.clear();
    currentTotalController.add(_currentTotal);
    Orders.ordersPushedController.add(null);
    Orders.ordersUpdatedController.add(Orders.orders);

    return future;
  }
}
