import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

class OrderItem {
  String id, shopId, userId, name, shopName;
  // null means not fulfilled
  String? fulfillerId;
  int count;
  double price;
  DatabaseReference get databaseReference =>
      Database.userReference.child('orders/$shopId/$id');

  OrderItem(this.id, this.shopId, this.userId, this.name, this.shopName,
      this.count, this.price,
      {this.fulfillerId});
}

class Database {
  static var storage = FirebaseStorage.instance.ref();
  static var realtime = FirebaseDatabase.instance.ref();

  static late String groupId, userId;
  static DatabaseReference get userReference =>
      Database.realtime.child('users/${Database.groupId}/${Database.userId}');

  static DatabaseReference getOrderItemReference(OrderItem item) {
    return userReference.child('orders/${item.shopId}/${item.id}');
  }
}

class Shop {
  // shop database
  static late String _shopId;
  static String get shopId => _shopId;
  static set shopId(String newShopId) {
    if (newShopId == _shopId) {
      return;
    }

    _shopId = newShopId;
    _currentOrder.clear();
    _currentTotal = 0;

    _shopChangedController.add(_shopId);
  }

  static get shopName => _getShopName(_shopId);

  static Map<dynamic, dynamic> shops = {};
  static Map<dynamic, dynamic> get items {
    return shops[_shopId]['items'];
  }

  static String _getShopName(String shopId) {
    return shops[shopId]?['name'] ?? 'Unknown Shop';
  }

  static dynamic _getItem(String itemId) {
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
    onUpdate(_shopId);
    return _shopChangedController.stream.listen(onUpdate);
  }

  // local
  // shopId, itemId -> count
  static final Map<String, int> _currentOrder = {};
  static Map<String, int> get currentOrder => _currentOrder;
  static String get currentOrderString {
    String result = '';

    for (var item in _currentOrder.entries) {
      result += '- ${item.value}x\t${_getItem(item.key)['name']}\n';
    }

    return result;
  }

  static double _openTotal = 0;
  // shopId, itemId -> count
  static final _openOrders = <String, Map<String, int>>{};
  // shopId, fulfillerId, itemId -> count
  static final _fulfilledOrders = <String, Map<String, Map<String, int>>>{};
  static final _flattenedOpenOrders = <OrderItem>[];
  static final _flattenedFulfilledOrders = <OrderItem>[];

  static double get openTotal => _openTotal;
  static Map? get openOrder => _openOrders[_shopId];
  static Map<String, Map> get openOrders => _openOrders;
  static Map<String, Map> get fulfilledOrders => _fulfilledOrders;
  static List<OrderItem> get flattenedOpenOrders => _flattenedOpenOrders;
  static List<OrderItem> get flattenedFulfilledOrders =>
      _flattenedFulfilledOrders;

  static final StreamController<List<OrderItem>> _ordersUpdatedController =
      StreamController.broadcast();
  static StreamSubscription<List<OrderItem>> subscribeToOrderUpdated(
      void Function(List<OrderItem> orders) onUpdate) {
    return _ordersUpdatedController.stream.listen(onUpdate);
  }

  static void pushOpenOrderStream() {
    _openTotal = 0;
    _flattenedOpenOrders.clear();

    // flatten orders
    _openOrders.forEach((shopId, order) {
      order.forEach((itemId, count) {
        var item = _getItem(itemId);
        var price = count * (item['price'] as double);
        _openTotal += price;

        _flattenedOpenOrders.add(OrderItem(
          itemId,
          shopId,
          Database.userId,
          item['name'],
          _getShopName(shopId),
          count,
          price,
        ));
      });
    });

    _ordersUpdatedController.add(_flattenedOpenOrders);
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

  static void setOpenOrders(DataSnapshot snapshot) {
    if (snapshot.value == null) {
      return;
    }

    _openOrders.clear();

    for (var shop in (snapshot.value as Map).entries) {
      if (!_openOrders.containsKey(shop.key)) {
        _openOrders[shop.key] = {};
      }

      for (var item in shop.value.entries) {
        _openOrders[shop.key]?[item.key] = item.value;
      }
    }
  }

  static void setFulfilledOrders(DataSnapshot snapshot) {
    if (snapshot.value == null) {
      return;
    }

    _fulfilledOrders.clear();

    for (var shop in (snapshot.value as Map).entries) {
      if (!_fulfilledOrders.containsKey(shop.key)) {
        _fulfilledOrders[shop.key] = {};
      }

      for (var fulfiller in shop.value.entries) {
        if (!_fulfilledOrders[shop.key]!.containsKey(fulfiller.key)) {
          _fulfilledOrders[shop.key]?[fulfiller.key] = {};
        }

        for (var item in fulfiller.value.entries) {
          _fulfilledOrders[shop.key]?[fulfiller.key]?[item.key] = item.value;
        }
      }
    }
  }

  static Future<void> loadAll() async {
    var snapshot = await Database.realtime.child('shops').get();
    shops = snapshot.value as Map;
    _shopId = shops.keys.first;

    var orderFutures = <Future>[];

    for (String currentShopId in shops.keys) {
      // list product images for the shop
      var snapshot =
          await Database.storage.child('shops/$currentShopId/items').listAll();
      _itemReferences[currentShopId] = snapshot.items;

      // get users open orders for the shop
      orderFutures.add(
        Database.userReference
            .child('orders')
            .get()
            .then((snapshot) => setOpenOrders(snapshot)),
      );

      orderFutures.add(
        Database.userReference
            .child('fulfilled')
            .get()
            .then((snapshot) => setFulfilledOrders(snapshot)),
      );

      // notify subscribers once all orders are loaded
      Future.wait(orderFutures).then((_) {
        pushOpenOrderStream();
      });
    }

    orderUpdateListener(event) {
      switch (event.snapshot.key) {
        case 'orders':
          setOpenOrders(event.snapshot);
          pushOpenOrderStream();
          break;
        case 'fulfilled':
          setFulfilledOrders(event.snapshot);
          break;
        default:
          break;
      }
    }

    Database.userReference.onChildAdded.listen(orderUpdateListener);
    Database.userReference.onChildChanged.listen(orderUpdateListener);
  }

  static bool containsReference(String referencePath) {
    var reference = Database.storage.child(referencePath);
    return _itemReferences[_shopId]?.contains(reference) ?? false;
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

  static Future<void> pushCurrentShopOrder() {
    var order = _openOrders[_shopId] ?? <String, int>{};

    _currentOrder.forEach((key, value) {
      int count = order[key] ?? 0;
      order[key] = count + value;
    });

    var future = Database.userReference.child('orders/$_shopId').set(order);
    _openOrders[_shopId] = order;

    _currentTotal = 0;
    _currentOrder.clear();
    _currentTotalController.add(_currentTotal);
    pushOpenOrderStream();

    return future;
  }

  static Future<void> removeItem(OrderItem item) {
    return item.databaseReference.remove().then((_) {
      _openOrders[shopId]?.remove(item.id);
      pushOpenOrderStream();
    });
  }

  static Future<void>? fulfillItem(OrderItem item, int count) {
    if (item.fulfillerId == null) {
      return null;
    }

    var futures = <Future>[];

    // skip fulfilling own order
    if (item.fulfillerId != Database.userId) {
      int fulfilledCount =
          _fulfilledOrders[_shopId]?[item.fulfillerId]?[item.id] ?? 0;

      futures.add(Database.userReference
          .child('fulfilled/$_shopId/${item.fulfillerId}/${item.id}')
          .set(fulfilledCount + count));
    }

    if (item.count == count) {
      futures.add(item.databaseReference.remove());
    } else {
      futures.add(item.databaseReference.set(item.count - count));
    }

    return Future.wait(futures);
  }
}
