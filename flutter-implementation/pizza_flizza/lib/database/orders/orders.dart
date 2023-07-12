import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/item.dart';

import 'order.dart';

/// userId, shopId -> order
typedef OrderMap = Map<String, Map<String, Order>>;

extension OrderAccessExtension on OrderMap {
  Order? getOrder(String userId, String shopId) {
    var userOrders = this[userId];
    return userOrders?[shopId];
  }

  void setOrder(String userId, String shopId, Order order) {
    var userOrders = this[userId];
    userOrders ??= {};

    userOrders[shopId] = order;
  }

  void setItem(String userId, String shopId, OrderItem item) {
    var userOrders = this[userId];
    userOrders ??= {};
    var shopOrder = userOrders[shopId];
    if (shopOrder == null) {
      userOrders[shopId] = Order(shopId, {item.itemId: item});
    } else {
      shopOrder.items.addAll({item.itemId: item});
    }
  }

  bool removeOrder(String userId, String shopId) {
    var userOrders = this[userId];

    if (!(userOrders?.containsKey(shopId) ?? false)) {
      return false;
    }

    userOrders!.remove(shopId);
    return true;
  }
}

/// fulfillerId, shopId, userId -> order
typedef FulfilledMap = Map<String, Map<String, Map<String, FulfilledOrder>>>;

/// userId, shopId, timestamp -> order
typedef HistoryMap = Map<String, Map<String, Map<int, HistoryOrder>>>;

/// userId, shopId, categoryId, itemId -> count
typedef StatMap = Map<String, Map<String, Map<String, Map<String, int>>>>;

class Orders {
  static final OrderMap orders = {};
  static final FulfilledMap fulfilled = {};
  static final HistoryMap history = {};
  static final StatMap stats = {};

  static Map<String, Map<String, Map<String, int>>>? get userStats {
    var userId = Database.currentUser?.userId;
    return userId == null ? null : stats[userId];
  }

  static final StreamController<void> ordersPushedController =
      StreamController.broadcast();
  static StreamSubscription subscribeToOrdersPushed(
      void Function(void) onUpdate) {
    return ordersPushedController.stream.listen(onUpdate);
  }

  static final StreamController<OrderMap> ordersUpdatedController =
      StreamController.broadcast();
  static StreamSubscription<OrderMap> subscribeToOrdersUpdated(
      void Function(OrderMap orders) onUpdate) {
    onUpdate(orders);
    return ordersUpdatedController.stream.listen(onUpdate);
  }

  static final StreamController<FulfilledMap> fulfilledUpdatedController =
      StreamController.broadcast();
  static StreamSubscription<FulfilledMap> subscribeToFulfilledUpdated(
      void Function(FulfilledMap orders) onUpdate) {
    onUpdate(fulfilled);
    return fulfilledUpdatedController.stream.listen(onUpdate);
  }

  static final StreamController<HistoryMap> historyUpdatedController =
      StreamController.broadcast();
  static StreamSubscription<HistoryMap> subscribeToHistoryUpdated(
      void Function(HistoryMap orders) onUpdate) {
    onUpdate(history);
    return historyUpdatedController.stream.listen(onUpdate);
  }

  static final StreamController<StatMap> statsUpdatedController =
      StreamController.broadcast();
  static StreamSubscription<StatMap> subscribeToStatsUpdated(
      void Function(StatMap stats) onUpdate) {
    onUpdate(stats);
    return statsUpdatedController.stream.listen(onUpdate);
  }

  static StreamSubscription<DatabaseEvent>? groupDataAddedSubscription,
      groupDataChangedSubscription,
      groupDataRemovedSubscription;
}

extension MapUtility on Map {
  Map get deepClone => deepCloneMap(this);

  Map deepCloneMap(Map originalMap) {
    Map clonedMap = {};

    originalMap.forEach((key, value) {
      if (value is Map) {
        clonedMap[key] = deepCloneMap(value); // Recursively clone nested maps
      } else {
        clonedMap[key] = value; // Copy non-map values directly
      }
    });

    return clonedMap;
  }
}
