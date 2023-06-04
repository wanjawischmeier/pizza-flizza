import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pizza_flizza/logger.util.dart';

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

  static get currentShopName => _getShopName(_currentShopId);

  static Map<dynamic, dynamic> shops = {};
  static Map<dynamic, dynamic> get items {
    return shops[_currentShopId]['items'];
  }

  static String _getShopName(String shopId) {
    return shops[shopId]?['name'] ?? 'Unknown Shop';
  }

  static dynamic _getItemInfo(String itemId) {
    for (var shop in shops.values) {
      for (var category in shop['items'].values) {
        for (var item in category.entries) {
          if (item.key == itemId) {
            return item.value;
          }
        }
      }
    }

    return 'Unknown Item';
  }

  static final StreamController<String> _shopChangedController =
      StreamController.broadcast();
  static StreamSubscription<String> subscribeToShopChanged(
      void Function(String shopId) onUpdate) {
    onUpdate(_currentShopId);
    return _shopChangedController.stream.listen(onUpdate);
  }

  // local
  // shopId, itemId -> count
  static final Map<String, int> _currentOrder = {};
  static Map<String, int> get currentOrder => _currentOrder;
  static String get currentOrderString {
    String result = '';

    for (var item in _currentOrder.entries) {
      result += '- ${item.value}x\t${_getItemInfo(item.key)['name']}\n';
    }

    return result;
  }

  // userId, shopId
  static final OrderMap _orders2 = {};
  static OrderMap get orders2 => _orders2;
  // fulfillerId, shopId, userId
  static final FulfilledMap _fulfilled2 = {};
  // userId, shopId
  static final HistoryMap _history2 = {};

  static final StreamController _ordersPushedController2 =
      StreamController.broadcast();
  static StreamSubscription subscribeToOrdersPushed2(
      void Function(void) onUpdate) {
    return _ordersPushedController2.stream.listen(onUpdate);
  }

  static final StreamController<OrderMap> _ordersUpdatedController2 =
      StreamController.broadcast();
  static StreamSubscription<OrderMap> subscribeToOrdersUpdated2(
      void Function(OrderMap orders) onUpdate) {
    onUpdate(_orders2);
    return _ordersUpdatedController2.stream.listen(onUpdate);
  }

  static final StreamController<FulfilledMap> _fulfilledUpdatedController2 =
      StreamController.broadcast();
  static StreamSubscription<FulfilledMap> subscribeToFulfilledUpdated2(
      void Function(FulfilledMap orders) onUpdate) {
    onUpdate(_fulfilled2);
    return _fulfilledUpdatedController2.stream.listen(onUpdate);
  }

  static double _openTotal = 0;
  // shopId, fulfillerId, itemId -> count
  static final _fulfilledOrders2 = <String, Map<String, Map<String, int>>>{};
  static final _openOrders = <OpenItem>[];
  static final _fulfilledOrders = <FulfilledItem>[];

  static double get openTotal => _openTotal;
  static List<OpenItem> get openOrders => _openOrders;
  static List<OpenItem> get openShopOrders =>
      _openOrders.where((order) => order.shopId == _currentShopId).toList();
  static List<OpenItem> get openShopUserOrders => _openOrders
      .where((order) =>
          order.shopId == _currentShopId && order.userId == Database.userId)
      .toList();
  static List<FulfilledItem> get fulfilledOrders => _fulfilledOrders;

  static final StreamController<List<OpenItem>> _ordersUpdatedController =
      StreamController.broadcast();
  static StreamSubscription<List<OpenItem>> subscribeToOrderUpdated(
      void Function(List<OpenItem> orders) onUpdate) {
    return _ordersUpdatedController.stream.listen(onUpdate);
  }

  static double _currentTotal = 0;
  static final StreamController<double> _currentTotalController =
      StreamController.broadcast();
  static StreamSubscription<double> subscribeToCurrentTotal(
      void Function(double total) onUpdate) {
    onUpdate(_currentTotal);
    return _currentTotalController.stream.listen(onUpdate);
  }

  static final Map<String, List<Reference>> _itemReferences = {};

  static void parseOpenUserOrders2(String userId, Map? userOrders) {
    // skip empty orders
    if (userOrders == null) {
      return;
    }

    bool modified = false;

    // initialize user orders entry
    if (!_orders2.containsKey(userId)) {
      _orders2[userId] = {};
    }

    // iterate over all shops containing orders
    for (var shopEntry in userOrders.entries) {
      String shopId = shopEntry.key;
      Map shop = shopEntry.value;
      var items = <String, OrderItem2>{};

      for (var itemEntry in shop.entries) {
        String itemId = itemEntry.key;
        Map item = itemEntry.value;

        // get item info
        var itemInfo = _getItemInfo(itemId);
        String itemName = itemInfo['name'];
        String shopName = _getShopName(shopId);
        int timestamp = item['timestamp'];
        int count = item['count'];
        double price = count * (itemInfo['price'] as double);

        // create instance
        var orderItem = OrderItem2(
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
        var previousItem = _orders2[userId]?[shopId]?.items[itemId];
        if (orderItem != previousItem) {
          modified = true;
        }

        items[itemId] = orderItem;
      }

      _orders2[userId]?[shopId] = Order2(items);
      log.logOrderItems(items, userId, shopId, null);
    }

    // if orders changed: notify listeners
    if (modified) {
      _ordersUpdatedController2.add(_orders2);
    }
  }

  static void parseUserFulfilledOrders2(
      String fulfillerId, Map? fulfilledOrders) {
    // skip empty orders
    if (fulfilledOrders == null) {
      return;
    }

    bool modified = false;

    if (!_fulfilled2.containsKey(fulfillerId)) {
      _fulfilled2[fulfillerId] = {};
    }

    // iterate over all shops containing orders
    for (var shopEntry in fulfilledOrders.entries) {
      String shopId = shopEntry.key;
      Map fulfilledShop = shopEntry.value;

      if (!(_fulfilled2[fulfillerId]?.containsKey(shopId) ?? false)) {
        _fulfilled2[fulfillerId]?[shopId] = {};
      }

      for (var userEntry in fulfilledShop.entries) {
        String userId = userEntry.key;
        Map fulfilledItems = userEntry.value;
        var items = <String, OrderItem2>{};

        for (var itemEntry in fulfilledItems.entries) {
          String itemId = itemEntry.key;
          Map item = itemEntry.value;

          // get item info
          var itemInfo = _getItemInfo(itemId);
          String itemName = itemInfo['name'];
          String shopName = _getShopName(shopId);
          int timestamp = item['timestamp'];
          int count = item['count'];
          double price = count * (itemInfo['price'] as double);

          // create instance
          var orderItem = OrderItem2(
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
              _fulfilled2[fulfillerId]?[shopId]?[userId]?.items[itemId];
          if (orderItem != previousItem) {
            modified = true;
          }

          items[itemId] = orderItem;
        }

        _fulfilled2[fulfillerId]?[shopId]?[userId] = Order2(items);
        log.logOrderItems(items, userId, shopId, fulfillerId);
      }
    }

    // if orders changed: notify listeners
    if (modified) {
      _fulfilledUpdatedController2.add(_fulfilled2);
    }
  }

  static Future<void> loadAll() async {
    var snapshot = await Database.realtime.child('shops').get();
    shops = snapshot.value as Map;
    _currentShopId = shops.keys.first;

    for (String currentShopId in shops.keys) {
      // list product images for the shop
      var snapshot =
          await Database.storage.child('shops/$currentShopId/items').listAll();
      _itemReferences[currentShopId] = snapshot.items;
    }

    orderUpdateListener(event) {
      String updatedUserId = event.snapshot.key;
      Map? data = event.snapshot.value;
      if (data == null) {
        return;
      }

      if (data.containsKey('orders')) {
        parseOpenUserOrders2(updatedUserId, data['orders']);
      }

      if (data.containsKey('fulfilled')) {
        parseUserFulfilledOrders2(updatedUserId, data['fulfilled']);
      }
    }

    var users = Database.realtime.child('users/${Database.groupId}');
    users.onChildAdded.listen(orderUpdateListener);
    users.onChildChanged.listen(orderUpdateListener);
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
    var orders = <String, Map<String, int>>{};
    var items = _orders2[Database.userId]?[_currentShopId]?.items ?? {};

    // initialize with current
    _currentOrder.forEach((itemId, count) {
      orders[itemId] = <String, int>{
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'count': count,
      };

      // get item info
      var itemInfo = _getItemInfo(itemId);
      String itemName = itemInfo['name'];
      String shopName = _getShopName(_currentShopId);
      int timestamp = DateTime.now().millisecondsSinceEpoch;
      double price = count * (itemInfo['price'] as double);

      items[itemId] = OrderItem2(
        itemId,
        _currentShopId,
        Database.userId,
        timestamp,
        itemName,
        shopName,
        count,
        price,
      );
      items;
    });

    // loop through and add existing
    for (var itemEntry in items.entries) {
      var itemId = itemEntry.key;
      var item = itemEntry.value;

      orders[itemId] = <String, int>{
        'timestamp': orders[itemId]?['timestamp'] ?? item.timestamp,
        'count': item.count + (orders[itemId]?['count'] ?? 0),
      };
    }

    var future =
        Database.userReference.child('orders/$_currentShopId').set(orders);

    _openTotal = 0;
    _currentTotal = 0;
    _currentOrder.clear();
    _currentTotalController.add(_currentTotal);
    _ordersPushedController2.add(null);
    _ordersUpdatedController2.add(_orders2);

    return future;
  }

  static Future<void> removeItem(ShopItem item) {
    // _openOrders[shopId]?.remove(item.id);
    return item.databaseReference.remove();
  }

  static Future<void>? fulfillItem(OrderItem2 item, int count) {
    var futures = <Future>[];

    // skip fulfilling own order
    if (item.userId != Database.userId || true) {
      int fulfilledCount = _fulfilled2[Database.userId]?[item.shopId]
                  ?[item.userId]
              ?.items[item.itemId]
              ?.count ??
          0;

      if (!_fulfilled2.containsKey(Database.userId)) {
        _fulfilled2[Database.userId] = {};

        if (!_fulfilled2[Database.userId]!.containsKey(item.shopId)) {
          _fulfilled2[Database.userId]![item.shopId] = {};
        }

        if (!_fulfilled2[Database.userId]![item.shopId]!
            .containsKey(item.userId)) {
          _fulfilled2[Database.userId]![item.shopId]![item.userId] = Order2({
            item.itemId: OrderItem2.copy(item),
          });
        }
      }

      var fulfilledItem =
          _fulfilled2[Database.userId]![item.shopId]![item.userId]!
                  .items[item.itemId] ??
              OrderItem2.copy(item);
      fulfilledItem.count = fulfilledCount + count;
      // update price!
      fulfilledItem.price = -1;

      Map map = {
        'count': fulfilledCount + count,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      var reference = Database.userReference
          .child('fulfilled/${item.shopId}/${item.userId}/${item.itemId}');
      futures.add(reference.set(map));
    }

    if (item.count <= count) {
      _orders2[item.userId]?[item.shopId]?.items.remove(item.itemId);
      futures.add(item.databaseReference.remove());
    } else {
      item.count -= count;
      _orders2[item.userId]?[item.shopId]?.items[item.itemId]?.count =
          item.count;
      futures.add(item.databaseReference.child('count').set(item.count));
    }

    return Future.wait(futures);
  }
}
