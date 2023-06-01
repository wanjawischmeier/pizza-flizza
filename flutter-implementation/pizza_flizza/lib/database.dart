import 'dart:async';
import 'dart:core';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

typedef OrderMap = Map<String, Map<String, Order2>>;
typedef FulfilledMap = Map<String, Map<String, Map<String, FulfilledOrder2>>>;
typedef HistoryMap = Map<String, Map<String, FulfilledOrder2>>;

class ShopItem2 {
  String shopId, userId, itemName, shopName;
  int count;
  double price;

  ShopItem2(
    this.shopId,
    this.userId,
    this.itemName,
    this.shopName,
    this.count,
    this.price,
  );
}

class OrderItem2 extends ShopItem2 {
  int timestamp;

  OrderItem2(
    super.shopId,
    super.userId,
    this.timestamp,
    super.itemName,
    super.shopName,
    super.count,
    super.price,
  );
}

class FulfilledItem2 extends ShopItem2 {
  String itemId;

  FulfilledItem2(
    this.itemId,
    super.shopId,
    super.userId,
    super.itemName,
    super.shopName,
    super.count,
    super.price,
  );
}

class Order2 {
  // itemId
  Map<String, OrderItem2> items;

  Order2(this.items);
}

class FulfilledOrder2 {
  String userId, fulfillerId;
  int timestamp;
  double price;
  List<FulfilledItem2> items;

  FulfilledOrder2(
      this.userId, this.fulfillerId, this.timestamp, this.price, this.items);
}

class ShopItem {
  String id, shopId, userId, name, shopName;
  int count;
  double price;
  DatabaseReference get databaseReference =>
      Database.userReference.child('orders/$shopId/$id');

  ShopItem(
    this.id,
    this.shopId,
    this.userId,
    this.name,
    this.shopName,
    this.count,
    this.price,
  );

  static ShopItem? getById(List<ShopItem> orders, String id) {
    var matching = orders.where((order) => order.id == id);
    return matching.isEmpty ? null : matching.first;
  }
}

class OpenItem extends ShopItem {
  int timestamp;

  OpenItem(
    super.id,
    super.shopId,
    super.userId,
    this.timestamp,
    super.name,
    super.shopName,
    super.count,
    super.price,
  );

  OpenItem.fromNow(ShopItem shopItem)
      : timestamp = DateTime.now().millisecondsSinceEpoch,
        super(
          shopItem.id,
          shopItem.shopId,
          shopItem.userId,
          shopItem.name,
          shopItem.shopName,
          shopItem.count,
          shopItem.price,
        );
}

class FulfilledItem extends OpenItem {
  String fulfillerId;

  FulfilledItem(
    super.id,
    super.shopId,
    super.userId,
    this.fulfillerId,
    super.name,
    super.shopName,
    super.count,
    super.price,
    super.timestamp,
  );

  FulfilledItem.fromOpenNow(OpenItem openItem, this.fulfillerId)
      : super(
          openItem.id,
          openItem.shopId,
          openItem.userId,
          DateTime.now().millisecondsSinceEpoch,
          openItem.name,
          openItem.shopName,
          openItem.count,
          openItem.price,
        );

  static FulfilledItem? getById(List<FulfilledItem> orders, String id) {
    var matching = orders.where((order) => order.id == id);
    return matching.isEmpty ? null : matching.first;
  }
}

class Database {
  static var storage = FirebaseStorage.instance.ref();
  static var realtime = FirebaseDatabase.instance.ref();

  static late String groupId, userId;
  static DatabaseReference get groupReference =>
      Database.realtime.child('users/${Database.groupId}');
  static DatabaseReference get userReference =>
      Database.realtime.child('users/${Database.groupId}/${Database.userId}');

  static DatabaseReference getOrderItemReference(ShopItem item) {
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
      result += '- ${item.value}x\t${_getItemInfo(item.key)['name']}\n';
    }

    return result;
  }

  static double _openTotal = 0;
  // shopId, fulfillerId, itemId -> count
  static final _fulfilledOrders2 = <String, Map<String, Map<String, int>>>{};
  static final _openOrders = <OpenItem>[];
  static final _fulfilledOrders = <FulfilledItem>[];

  // userId, shopId
  static final OrderMap _orders2 = {};
  // userId, shopId, fulfillerId
  static final FulfilledMap _fulfilled2 = {};
  // userId, shopId
  static final HistoryMap _history2 = {};

  static final StreamController<OrderMap> _ordersUpdatedController2 =
      StreamController.broadcast();
  static StreamSubscription<OrderMap> subscribeToOrdersUpdated2(
      void Function(OrderMap orders) onUpdate) {
    onUpdate(_orders2);
    return _ordersUpdatedController2.stream.listen(onUpdate);
  }

  static double get openTotal => _openTotal;
  static List<OpenItem> get openOrders => _openOrders;
  static List<OpenItem> get openShopOrders =>
      _openOrders.where((order) => order.shopId == _shopId).toList();
  static List<OpenItem> get openShopUserOrders => _openOrders
      .where(
          (order) => order.shopId == _shopId && order.userId == Database.userId)
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

  static void setOpenUserOrders2(String userId, Map? userOrders) {
    // skip empty orders
    if (userOrders == null) {
      return;
    }

    // clear?
    // _orders2.clear();

    // initialize user orders entry
    if (!_orders2.containsKey(userId)) {
      _orders2[userId] = {};
    }

    // iterate over all shops containing orders
    for (var shop in userOrders.entries) {
      var items = <String, OrderItem2>{};

      for (var item in shop.value.entries) {
        var itemInfo = _getItemInfo(item.key);
        String itemName = itemInfo['name'];
        int timestamp = item.value['timestamp'];
        int count = item.value['count'];
        double price = count * (itemInfo['price'] as double);

        var orderItem = OrderItem2(
          shop.key,
          userId,
          timestamp,
          itemName,
          shopName,
          count,
          price,
        );

        items[item.key] = orderItem;
      }

      _orders2[userId]?[shop.key] = Order2(items);
    }

    _ordersUpdatedController2.add(_orders2);
  }

  static void setOpenUserOrders(String userId, Map? userOrders) {
    if (userOrders == null) {
      return;
    }

    // iterate over all shops containing orders
    for (var shop in userOrders.entries) {
      for (var item in shop.value.entries) {
        var itemInfo = _getItemInfo(item.key);
        int timestamp = item.value['timestamp'];
        int count = item.value['count'];
        double price = count * (itemInfo['price'] as double);
        var orderItem = OpenItem(
          item.key,
          shop.key,
          userId,
          timestamp,
          itemInfo['name'],
          _getShopName(shop.key),
          count,
          price,
        );

        // get existing order item with potentially different count
        var matching = _openOrders.where((matchingItem) {
          return matchingItem.id == orderItem.id &&
              matchingItem.shopId == orderItem.shopId &&
              matchingItem.userId == orderItem.userId;
        });

        if (matching.isNotEmpty) {
          int index = _openOrders.indexOf(matching.first);
          _openOrders[index] = orderItem;
        } else {
          _openOrders.add(orderItem);
        }
      }
    }

    _ordersUpdatedController.add(_openOrders);
  }

  static void setFulfilledOrders(DataSnapshot snapshot) {
    if (snapshot.value == null) {
      return;
    }

    _fulfilledOrders2.clear();

    for (var shop in (snapshot.value as Map).entries) {
      if (!_fulfilledOrders2.containsKey(shop.key)) {
        _fulfilledOrders2[shop.key] = {};
      }

      for (var fulfiller in shop.value.entries) {
        if (!_fulfilledOrders2[shop.key]!.containsKey(fulfiller.key)) {
          _fulfilledOrders2[shop.key]?[fulfiller.key] = {};
        }

        for (var item in fulfiller.value.entries) {
          _fulfilledOrders2[shop.key]?[fulfiller.key]?[item.key] = item.value;
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

      /*
      // get users open orders for the shop
      orderFutures.add(
        Database.groupReference
            .get()
            .then((snapshot) => setOpenUserOrders(snapshot.value as Map?)),
      );
      */
      /*
      orderFutures.add(
        Database.userReference
            .child('fulfilled')
            .get()
            .then((snapshot) => setFulfilledOrders(snapshot)),
      );
      */
      // notify subscribers once all orders are loaded
      /*
      Future.wait(orderFutures).then((_) {
        pushOpenOrderStream();
      });
      */
    }

    orderUpdateListener(event) {
      String updatedUserId = event.snapshot.key;
      Map? data = event.snapshot.value;
      if (data == null) {
        return;
      }

      setOpenUserOrders(updatedUserId, data['orders']);

      if (data.containsKey('fulfilled')) {
        setFulfilledOrders(data['fulfilled']);
      }
    }

    var users = Database.realtime.child('users/${Database.groupId}');
    users.onChildAdded.listen(orderUpdateListener);
    users.onChildChanged.listen(orderUpdateListener);
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

  static Future<void>? pushCurrentOrder() {
    var orders = <String, Map<String, int>>{};
    var existingOrders = openShopUserOrders;

    // initialize with current
    _currentOrder.forEach((id, count) {
      orders[id] = <String, int>{
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'count': count,
      };
    });

    // loop through and add existing
    for (var order in existingOrders) {
      orders[order.id] = <String, int>{
        'timestamp': orders[order.id]?['timestamp'] ?? order.timestamp,
        'count': order.count + (orders[order.id]?['count'] ?? 0),
      };
    }

    var future = Database.userReference.child('orders/$_shopId').set(orders);

    // update local database; optional, will be updated with upstream
    // _openOrders[_shopId]?[Database.userId] = orders;

    _openTotal = 0;
    _currentTotal = 0;
    _currentOrder.clear();
    _currentTotalController.add(_currentTotal);

    return future;
  }

  static Future<void> removeItem(ShopItem item) {
    // _openOrders[shopId]?.remove(item.id);
    return item.databaseReference.remove();
  }

  static Future<void>? fulfillItem(OpenItem item, int count) {
    var futures = <Future>[];

    // skip fulfilling own order
    if (item.userId != Database.userId) {
      var fulfilled = FulfilledItem.fromOpenNow(item, Database.userId);
      /*
      int fulfilledCount =
          _fulfilledOrders2[_shopId]?[item.fulfillerId]?[item.id] ?? 0;

      futures.add(Database.userReference
          .child('fulfilled/$_shopId/${item.fulfillerId}/${item.id}')
          .set(fulfilledCount + count));
          */
    }

    if (item.count == count) {
      futures.add(item.databaseReference.remove());
    } else {
      futures.add(item.databaseReference.set(item.count - count));
    }

    return Future.wait(futures);
  }
}
