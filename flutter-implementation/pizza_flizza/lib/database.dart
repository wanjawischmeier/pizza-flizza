import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

typedef OnShopChanged = void Function();

class Database {
  static var storage = FirebaseStorage.instance.ref();
  static var realtime = FirebaseDatabase.instance.ref();
}

class Shop {
  // shop database
  static late String _shopId;
  static OnShopChanged? onChanged;
  static Map<dynamic, dynamic> shops = {};
  static Map<dynamic, dynamic> get items {
    return shops[shopId]['items'];
  }

  // local
  // shopId, itemId -> count
  static final Map<String, Map<String, int>> _currentOrders = {};
  static Map<String, Map<String, int>> get currentOrders => _currentOrders;

  static int _currentOrderCount = 0;
  static final StreamController<int> _currentOrderCountController =
      StreamController.broadcast();
  static StreamSubscription<int> subscribeToOrderCount(
      void Function(int orderCount) onUpdate) {
    onUpdate(_currentOrderCount);
    return _currentOrderCountController.stream.listen(onUpdate);
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

  static String get shopId => _shopId;
  static set shopId(String newShopId) {
    _shopId = newShopId;
    onChanged?.call();
  }

  static Future<void> loadAll() async {
    var snapshot = await Database.realtime.child('shops').get();
    shops = snapshot.value as Map<dynamic, dynamic>;
    shopId = shops.keys.first;

    for (String shop in shops.keys) {
      var snapshot =
          await Database.storage.child('shops/$shop/items').listAll();
      _itemReferences[shop] = snapshot.items;
    }

    shopId;
  }

  static String? getItemImageReference(String itemId) {
    String path = 'shops/$_shopId/items/$itemId.png';
    var reference = Database.storage.child(path);
    if (_itemReferences[_shopId]?.contains(reference) ?? false) {
      return path;
    } else {
      return null;
    }
  }

  static void pushOrder(Map<String, Map<String, int>> newItems) {
    for (var category in newItems.entries) {
      for (var item in category.value.entries) {
        _currentOrders[_shopId]?[item.key] = item.value;
        _currentOrderCount += item.value;
        _currentTotal += items[category.key]?[item.key]?['price'] * item.value;
      }
    }

    _currentOrderCountController.add(_currentOrderCount);
    _currentTotalController.add(_currentTotal);
    _currentOrders.clear();
  }
}
