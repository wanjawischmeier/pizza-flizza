import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pizza_flizza/other/helper.dart';
import 'package:pizza_flizza/other/logger.util.dart';

import 'database.dart';
import 'item.dart';
import 'order.dart';

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

    _shopChangedController.add(_currentShopId);
  }

  static String get currentShopName => _getShopName(_currentShopId);

  static Map<dynamic, dynamic> shops = {};
  static Map<dynamic, dynamic> get items {
    return shops[_currentShopId]['items'];
  }

  static String _getShopName(String shopId) {
    return shops[shopId]?['name'] ?? 'database.unknown_shop'.tr();
  }

  static Map getItemInfo(String shopId, String itemId) {
    for (var categoryEntry in shops[shopId]['items'].entries) {
      String categoryId = categoryEntry.key;
      var category = categoryEntry.value;

      for (var itemEntry in category.entries) {
        if (itemEntry.key == itemId) {
          itemEntry.value['category'] = categoryId;
          return itemEntry.value;
        }
      }
    }

    return {
      'name': 'database.unknown_item_name'.tr(),
      'category': 'unknown_category_id',
      'price': '0',
      'bought': '0',
    };
  }

  static final StreamController<String> _shopChangedController =
      StreamController.broadcast();
  static StreamSubscription<String> subscribeToShopChanged(
      void Function(String shopId) onUpdate) {
    onUpdate(_currentShopId);
    return _shopChangedController.stream.listen(onUpdate);
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
  static final StreamController<double> _currentTotalController =
      StreamController.broadcast();
  static StreamSubscription<double> subscribeToCurrentTotal(
      void Function(double total) onUpdate) {
    onUpdate(_currentTotal);
    return _currentTotalController.stream.listen(onUpdate);
  }

  static void clearCurrentOrder() {
    _currentOrder.clear();
    _currentTotal = 0;
    _currentTotalController.add(_currentTotal);
  }

  static final OrderMap _orders = {};
  static OrderMap get orders => _orders;
  static final FulfilledMap _fulfilled = {};
  static FulfilledMap get fulfilled => _fulfilled;
  static final HistoryMap _history = {};

  static final StreamController _ordersPushedController =
      StreamController.broadcast();
  static StreamSubscription subscribeToOrdersPushed(
      void Function(void) onUpdate) {
    return _ordersPushedController.stream.listen(onUpdate);
  }

  static final StreamController<OrderMap> _ordersUpdatedController =
      StreamController.broadcast();
  static StreamSubscription<OrderMap> subscribeToOrdersUpdated(
      void Function(OrderMap orders) onUpdate) {
    onUpdate(_orders);
    return _ordersUpdatedController.stream.listen(onUpdate);
  }

  static final StreamController<FulfilledMap> _fulfilledUpdatedController =
      StreamController.broadcast();
  static StreamSubscription<FulfilledMap> subscribeToFulfilledUpdated(
      void Function(FulfilledMap orders) onUpdate) {
    onUpdate(_fulfilled);
    return _fulfilledUpdatedController.stream.listen(onUpdate);
  }

  static final StreamController<HistoryMap> _historyUpdatedController =
      StreamController.broadcast();
  static StreamSubscription<HistoryMap> subscribeToHistoryUpdated(
      void Function(HistoryMap orders) onUpdate) {
    onUpdate(_history);
    return _historyUpdatedController.stream.listen(onUpdate);
  }

  static StreamSubscription<DatabaseEvent>? _groupDataAddedSubscription,
      _groupDataChangedSubscription,
      _groupDataRemovedSubscription;

  static final Map<String, List<Reference>> _itemReferences = {};

  static Future<void> parseOpenUserOrders(
      String userId, Map? userOrders) async {
    // clear map in case of empty orders
    if (userOrders == null) {
      if (_orders.containsKey(userId)) {
        _orders.remove(userId);
        _ordersUpdatedController.add(_orders);
      }

      return;
    }

    bool modified = false;

    // initialize user orders entry
    if (_orders.containsKey(userId)) {
      _orders[userId]!.clear();
    } else {
      _orders[userId] = {};
    }

    // iterate over all shops containing orders
    for (var shopEntry in userOrders.entries) {
      String shopId = shopEntry.key;
      String shopName = _getShopName(shopId);
      Map shop = shopEntry.value;
      var items = <String, OrderItem>{};

      for (var itemEntry in shop.entries) {
        String itemId = itemEntry.key;
        Map item = itemEntry.value;

        // get item info
        var itemInfo = getItemInfo(shopId, itemId);
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
        var previousItem = _orders[userId]?[shopId]?.items[itemId];
        if (orderItem != previousItem) {
          modified = true;
        }

        items[itemId] = orderItem;
      }

      _orders[userId]?[shopId] = Order(
        shopId,
        shopName,
        items,
      );
      log.logOrderItems(items, userId, shopId, null);
    }

    // if orders changed: notify listeners
    if (modified) {
      _ordersUpdatedController.add(_orders);
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
      if (_fulfilled.containsKey(fulfillerId)) {
        _fulfilled.remove(fulfillerId);
        _fulfilledUpdatedController.add(_fulfilled);
      }

      return;
    }

    bool modified = false;

    if (_fulfilled.containsKey(fulfillerId)) {
      _fulfilled[fulfillerId]?.clear();
    } else {
      _fulfilled[fulfillerId] = {};
    }

    // iterate over all shops containing orders
    for (var shopEntry in fulfilledOrders.entries) {
      String shopId = shopEntry.key;
      String shopName = _getShopName(shopId);
      Map fulfilledShop = shopEntry.value;

      if (!(_fulfilled[fulfillerId]?.containsKey(shopId) ?? false)) {
        _fulfilled[fulfillerId]?[shopId] = {};
      }

      for (var userEntry in fulfilledShop.entries) {
        String userId = userEntry.key;
        Map fulfilledItems = userEntry.value;
        var items = <String, OrderItem>{};

        for (var itemEntry in fulfilledItems.entries) {
          String itemId = itemEntry.key;
          Map item = itemEntry.value;

          // get item info
          var itemInfo = getItemInfo(shopId, itemId);
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
              _fulfilled[fulfillerId]?[shopId]?[userId]?.items[itemId];
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

        _fulfilled[fulfillerId]?[shopId]?[userId] = FulfilledOrder.fromDate(
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
      _fulfilledUpdatedController.add(_fulfilled);
    }
  }

  static void parseHistoryUserOrders(String userId, Map? historyOrders) {
    // clear map in case of empty orders
    if (historyOrders == null) {
      if (_history.containsKey(userId)) {
        _history.remove(userId);
        _historyUpdatedController.add(_history);
      }

      return;
    }

    bool modified = false;

    if (_history.containsKey(userId)) {
      _history[userId]!.clear();
    } else {
      _history[userId] = {};
    }

    // iterate over all shops containing a history
    for (var shopEntry in historyOrders.entries) {
      String shopId = shopEntry.key;
      String shopName = _getShopName(shopId);
      Map shop = shopEntry.value;

      if (!(_history[userId]?.containsKey(shopId) ?? false)) {
        _history[userId]?[shopId] = {};
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
          var itemInfo = getItemInfo(shopId, itemId);
          String itemName = itemInfo['name'];
          double price = count * (itemInfo['price'] as double);

          // compare to previous item
          var previousCount =
              _history[userId]?[shopId]?[timestamp]?.items[itemId]?.count;
          if (count != previousCount) {
            modified = true;
          }

          items[itemId] = HistoryItem(
            itemName,
            count,
            price,
          );
        }

        _history[userId]?[shopId]?[timestamp] = HistoryOrder(
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
      _historyUpdatedController.add(_history);
    }
  }

  static Future<void> loadAll() async {
    var snapshot = await Database.realtime.child('shops').get();
    shops = snapshot.value as Map;
    _currentShopId = shops.keys.first;

    for (String currentShopId in shops.keys) {
      // list product images for the shop
      var imagesSnapshot = await Database.storage
          .child(
            'images/${Database.imageResolution}/shops/$currentShopId/items',
          )
          .listAll();
      _itemReferences[currentShopId] = imagesSnapshot.items;

      for (var categoryEntry in shops[currentShopId]['items'].entries) {
        var sorted =
            Helper.sortByComparator(categoryEntry.value, (item0, item1) {
          int bought0, bought1;

          if (item0.key == '0_name') {
            bought0 = 0;
          } else {
            bought0 = (item0.value as Map)['bought'];
          }

          if (item1.key == '0_name') {
            bought1 = 0;
          } else {
            bought1 = (item1.value as Map)['bought'];
          }

          if (bought0 == bought1) {
            return 0;
          } else {
            return bought0 < bought1 ? 1 : -1;
          }
        });

        shops[currentShopId]['items'][categoryEntry.key] = sorted;
      }
    }
  }

  static void clearOrderData() {
    _orders.clear();
    _fulfilled.clear();
    _history.clear();

    _ordersUpdatedController.add(_orders);
    _fulfilledUpdatedController.add(_fulfilled);
    _historyUpdatedController.add(_history);
  }

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
              _fulfilled.remove(updatedUserId);
              changed = true;
            }
          }
        }

        if (changed) {
          _fulfilledUpdatedController.add(_fulfilled);
        }
      }

      if (data.containsKey('orders')) {
        _orders.remove(updatedUserId);
        _ordersUpdatedController.add(_orders);
      }

      if (updatedUserId == user.userId && data.containsKey('history')) {
        _history.clear();
        _historyUpdatedController.add(_history);
      }
    }

    var users = Database.realtime.child('users/${user.group.groupId}');
    _groupDataAddedSubscription = users.onChildAdded.listen(onChildUpdated);
    _groupDataChangedSubscription = users.onChildChanged.listen(onChildUpdated);
    _groupDataRemovedSubscription = users.onChildRemoved.listen(onChildRemoved);
  }

  static Future<void> cancelUserGroupUpdates() async {
    await _groupDataAddedSubscription?.cancel();
    await _groupDataChangedSubscription?.cancel();
    await _groupDataRemovedSubscription?.cancel();

    _groupDataAddedSubscription = null;
    _groupDataChangedSubscription = null;
    _groupDataRemovedSubscription = null;
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
    _currentTotalController.add(_currentTotal);
  }

  static Future<void>? pushCurrentOrder() {
    var user = Database.currentUser;
    if (user == null) {
      return null;
    }

    var orderData = <String, Map<String, int>>{};
    var items = <String, OrderItem>{};
    var ordersUser = _orders[user.userId];
    if (ordersUser == null) {
      ordersUser = {
        _currentShopId: Order(
          _currentShopId,
          currentShopName,
          items,
        ),
      };
    } else {
      var ordersShop = ordersUser[_currentShopId];
      if (ordersShop == null) {
        ordersShop = Order(_currentShopId, currentShopName, items);
      } else {
        items = ordersShop.items;
      }
    }

    // initialize with existing
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
      // get item info
      var itemInfo = getItemInfo(_currentShopId, itemId);
      String itemName = itemInfo['name'];
      String shopName = _getShopName(_currentShopId);
      int timestamp = DateTime.now().millisecondsSinceEpoch;
      int newCount = count + (orderData[itemId]?['count'] ?? 0);
      double price = newCount * (itemInfo['price'] as double);

      orderData[itemId] = <String, int>{
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'count': newCount,
      };

      items[itemId] = OrderItem(
        itemId,
        _currentShopId,
        user.userId,
        timestamp,
        itemName,
        shopName,
        newCount,
        price,
      );
    });

    var future =
        Database.userReference?.child('orders/$_currentShopId').set(orderData);

    _currentTotal = 0;
    _currentOrder.clear();
    _currentTotalController.add(_currentTotal);
    _ordersPushedController.add(null);
    _ordersUpdatedController.add(_orders);

    return future;
  }

  static Future<void>? removeOrderItem(OrderItem item) {
    _orders[item.userId]?[item.shopId]?.items.remove(item.itemId);
    _ordersUpdatedController.add(_orders);
    return item.databaseReference?.remove();
  }

  static Future<void>? archiveFulfilledOrder(FulfilledOrder order) {
    var user = Database.currentUser;
    if (user == null) {
      return null;
    }
    var futures = <Future>[];

    // remove from fulfilled
    _fulfilled[order.fulfillerId]?[order.shopId]?.remove(order.userId);
    // clean map propagating up the tree
    if (_fulfilled[order.fulfillerId]?[order.shopId]?.isEmpty ?? false) {
      _fulfilled[order.fulfillerId]?.remove(order.shopId);

      if (_fulfilled[order.fulfillerId]?.isEmpty ?? false) {
        _fulfilled.clear();
      }
    }
    var fulfilledFuture = order.databaseReference?.remove();
    if (fulfilledFuture != null) {
      futures.add(fulfilledFuture);
    }

    HistoryOrder? existingOrder;
    _history[order.userId]?[order.shopId]?.forEach((timestamp, historyOrder) {
      // find recent existing order
      if ((timestamp - order.timestamp).abs() < Duration.millisecondsPerHour) {
        order.timestamp = timestamp;
        existingOrder = historyOrder;
      }
    });

    // add to history
    var historyOrder = HistoryOrder.fromFulfilledOrder(order);
    if (existingOrder != null) {
      historyOrder.items.addAll(existingOrder!.items);
    }
    var historyFuture = Database.realtime
        .child(
            'users/${user.group.groupId}/${order.userId}/history/${order.shopId}/${order.timestamp}')
        .set(historyOrder.itemsParsed);
    futures.add(historyFuture);

    _fulfilledUpdatedController.add(_fulfilled);
    // _historyUpdatedController.add(_history);
    return Future.wait(futures);
  }

  static Future<void>? fulfillItem(OrderItem item, int count) {
    var fulfiller = Database.currentUser;
    if (fulfiller == null) {
      return null;
    }

    var futures = <Future>[];
    var date = DateTime.now();

    // update fulfilled, skip fulfilling own order
    if (item.userId == fulfiller.userId) {
      var newItem = OrderItem.copy(item);
      newItem.count = count;

      archiveFulfilledOrder(
        FulfilledOrder.fromUserItem(
          newItem,
          fulfiller.userId,
          date,
        ),
      );
    } else {
      int fulfilledCount = _fulfilled[fulfiller.userId]?[item.shopId]
                  ?[item.userId]
              ?.items[item.itemId]
              ?.count ??
          0;

      var fulfilledOrder = FulfilledOrder.fromDate(
        fulfiller.userId,
        item.userId,
        item.shopId,
        item.shopName,
        date,
        {item.itemId: OrderItem.copy(item)},
      );

      if (_fulfilled.containsKey(fulfiller.userId)) {
        if (_fulfilled[fulfiller.userId]!.containsKey(item.shopId)) {
          if (_fulfilled[fulfiller.userId]![item.shopId]!
              .containsKey(item.userId)) {
            _fulfilled[fulfiller.userId]![item.shopId]![item.userId]!
                .items[item.itemId] = OrderItem.copy(item);
          } else {
            _fulfilled[fulfiller.userId]![item.shopId]![item.userId] =
                fulfilledOrder;
          }
        } else {
          _fulfilled[fulfiller.userId]![item.shopId] = {
            item.userId: fulfilledOrder,
          };
        }
      } else {
        _fulfilled[fulfiller.userId] = {
          item.shopId: {
            item.userId: fulfilledOrder,
          }
        };
      }

      var fulfilledItem =
          _fulfilled[fulfiller.userId]![item.shopId]![item.userId]!
                  .items[item.itemId] ??
              OrderItem.copy(item);
      fulfilledItem.count = fulfilledCount + count;
      // update price!
      fulfilledItem.price = -1;

      Map map = {
        'count': fulfilledCount + count,
        'timestamp': date.millisecondsSinceEpoch,
      };

      var reference = Database.userReference
          ?.child('fulfilled/${item.shopId}/${item.userId}/${item.itemId}');
      if (reference != null) {
        futures.add(reference.set(map));
      }
    }

    // update orders
    if (item.count <= count) {
      _orders[item.userId]?[item.shopId]?.items.remove(item.itemId);
      var future = item.databaseReference?.remove();
      if (future != null) {
        futures.add(future);
      }
    } else {
      item.count -= count;
      _orders[item.userId]?[item.shopId]?.items[item.itemId]?.count =
          item.count;
      var future = item.databaseReference?.child('count').set(item.count);
      if (future != null) {
        futures.add(future);
      }
    }

    // update shop stats
    item.shopInfo.bought += count;
    futures.add(
      item.shopReference.child('bought').set(item.shopInfo.bought),
    );

    _ordersUpdatedController.add(_orders);
    _fulfilledUpdatedController.add(_fulfilled);
    return Future.wait(futures);
  }

  static Future<void> clearUserHistory() async {
    _history.clear();
    _historyUpdatedController.add(_history);
    return Database.userReference?.child('history').remove();
  }
}
