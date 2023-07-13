import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/item.dart';
import 'package:pizza_flizza/other/logger.util.dart';

import 'order.dart';

var log = AppLogger();

/// userId, shopId -> order
typedef OrderMap = Map<String, Map<String, Order>>;

extension OrderAccessExtension on OrderMap {
  Map<String, Map<String, Order>> get deepClone {
    Map<String, Map<String, Order>> clonedMap = {};

    forEach((key1, value1) {
      Map<String, Order> clonedInnerMap = {};

      value1.forEach((key2, value2) {
        clonedInnerMap[key2] = Order.from(value2);
      });

      clonedMap[key1] = clonedInnerMap;
    });

    return clonedMap;
  }

  Order? getOrder(String userId, String shopId) {
    var userOrders = this[userId];
    return userOrders?[shopId];
  }

  OrderItem? getItem(String userId, String shopId, String itemId) =>
      getOrder(userId, shopId)?.items[itemId];

  void setItems(String userId, String shopId, Map<String, OrderItem> items) =>
      setOrder(
        userId,
        shopId,
        Order(shopId, items),
      );

  void setOrder(String userId, String shopId, Order order) {
    this[userId] ??= {};
    var userOrders = this[userId]!;

    userOrders[shopId] = order;
  }

  void setItem(String userId, String shopId, OrderItem item) {
    var userOrders = this[userId];
    userOrders ??= {};

    var order = userOrders[shopId];
    if (order == null) {
      userOrders[shopId] = Order(shopId, {item.itemId: item});
    } else {
      order.items.addAll({item.itemId: item});
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

  void logOrder(String userId, String shopId) {
    var items = this[userId]?[shopId]?.items;
    if (items != null) {
      log.logOrderItems(items, userId, shopId, null);
    }
  }
}

/// fulfillerId, shopId, userId -> order
typedef FulfilledMap = Map<String, Map<String, Map<String, FulfilledOrder>>>;

extension FulfilledAccessExtension on FulfilledMap {
  Order? getOrder(String fulfillerId, String shopId, String userId) {
    var fulfillerOrders = this[fulfillerId];
    var shopOrders = fulfillerOrders?[shopId];
    return shopOrders?[userId];
  }

  OrderItem? getItem(
    String fulfillerId,
    String shopId,
    String userId,
    String itemId,
  ) =>
      getOrder(fulfillerId, shopId, userId)?.items[itemId];

  void setItems(
    String fulfillerId,
    String shopId,
    String userId,
    Map<String, OrderItem> items,
  ) {
    var latestChange = 0;
    items.forEach((itemId, item) {
      if (item.timestamp > latestChange) {
        latestChange = item.timestamp;
      }
    });

    var order = FulfilledOrder(
      fulfillerId,
      userId,
      shopId,
      DateTime.fromMillisecondsSinceEpoch(latestChange),
      items,
    );

    setOrder(fulfillerId, shopId, userId, order);
  }

  void setOrder(
    String fulfillerId,
    String shopId,
    String userId,
    FulfilledOrder order,
  ) {
    this[fulfillerId] ??= {};
    var fulfillerOrders = this[fulfillerId]!;
    fulfillerOrders[shopId] ??= {};
    var shopOrders = fulfillerOrders[shopId]!;

    shopOrders[userId] = order;
  }

  void setItem(
    String fulfillerId,
    String shopId,
    String userId,
    OrderItem item,
  ) {
    this[fulfillerId] ??= {};
    var fulfillerOrders = this[fulfillerId]!;
    fulfillerOrders[shopId] ??= {};
    var shopOrders = fulfillerOrders[shopId]!;

    var order = shopOrders[userId];
    if (order == null) {
      shopOrders[userId] = FulfilledOrder(
        fulfillerId,
        userId,
        shopId,
        DateTime.now(),
        {item.itemId: item},
      );
    } else {
      order.items.addAll({item.itemId: item});
    }
  }

  bool removeOrder(String fulfillerId, String shopId, String userId) {
    var fulfillerOrders = this[fulfillerId];
    var shopOrders = fulfillerOrders?[shopId];

    if (!(shopOrders?.containsKey(userId) ?? false)) {
      return false;
    }

    shopOrders!.remove(userId);
    return true;
  }

  static var log = AppLogger();

  void logOrder(String fulfillerId, String shopId, String userId) {
    var items = this[fulfillerId]?[shopId]?[userId]?.items;
    if (items != null) {
      log.logOrderItems(items, userId, shopId, fulfillerId);
    }
  }
}

/// userId, shopId, timestamp -> order
typedef HistoryMap = Map<String, Map<String, Map<int, HistoryOrder>>>;

extension HistoryAccessExtension on HistoryMap {
  HistoryOrder? getOrder(String userId, String shopId, int timestamp) {
    var userOrders = this[userId];
    var shopOrders = userOrders?[shopId];
    return shopOrders?[timestamp];
  }

  HistoryItem? getItem(
    String userId,
    String shopId,
    int timestamp,
    String itemId,
  ) =>
      getOrder(userId, shopId, timestamp)?.items[itemId];

  void setItems(
    String userId,
    String shopId,
    DateTime date,
    Map<String, HistoryItem> items,
  ) =>
      setOrder(
        userId,
        shopId,
        date,
        HistoryOrder(
          shopId,
          date,
          items,
        ),
      );

  void setOrder(
    String userId,
    String shopId,
    DateTime date,
    HistoryOrder order,
  ) {
    this[userId] ??= {};
    var userOrders = this[userId]!;
    userOrders[shopId] ??= {};
    var shopOrders = userOrders[shopId]!;

    shopOrders[date.millisecondsSinceEpoch] = order;
  }

  void setItem(
    String userId,
    String shopId,
    int timestamp,
    HistoryItem item,
  ) {
    this[userId] ??= {};
    var userOrders = this[userId]!;
    userOrders[shopId] ??= {};
    var shopOrders = userOrders[shopId]!;

    var order = shopOrders[timestamp];
    if (order == null) {
      shopOrders[timestamp] = HistoryOrder(
        shopId,
        DateTime.now(),
        {item.itemId: item},
      );
    } else {
      order.items.addAll({item.itemId: item});
    }
  }

  bool removeOrder(String userId, String shopId, int timestamp) {
    var userOrders = this[userId];
    var shopOrders = userOrders?[shopId];

    if (!(shopOrders?.containsKey(timestamp) ?? false)) {
      return false;
    }

    shopOrders!.remove(timestamp);
    return true;
  }

  static var log = AppLogger();

  void logOrder(String userId, String shopId, int timestamp) {
    var items = this[userId]?[shopId]?[timestamp]?.items;
    if (items != null) {
      log.logHistoryOrderItems(items, userId, shopId);
    }
  }
}

/// userId, shopId, categoryId, itemId -> count
typedef StatMap = Map<String, Map<String, Map<String, Map<String, int>>>>;

extension StatAccessExtension on StatMap {
  int getStat(String userId, String shopId, String categoryId, String itemId) {
    var userStats = this[userId];
    var shopStats = userStats?[shopId];
    var categoryStats = shopStats?[categoryId];
    return categoryStats?[itemId] ?? 0;
  }

  void setStat(
    String userId,
    String shopId,
    String categoryId,
    String itemId,
    int count,
  ) {
    this[userId] ??= {};
    var userStats = this[userId]!;
    userStats[shopId] ??= {};
    var shopStats = userStats[shopId]!;
    shopStats[categoryId] ??= {};
    var categoryStats = shopStats[categoryId]!;

    categoryStats[itemId] = count;
  }

  bool clearStat(
    String userId,
    String shopId,
    String categoryId,
    String itemId,
  ) {
    var userStats = this[userId];
    var shopStats = userStats?[shopId];
    var categoryStats = shopStats?[categoryId];

    if (!(categoryStats?.containsKey(itemId) ?? false)) {
      return false;
    }

    categoryStats!.remove(itemId);
    return true;
  }
}

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
