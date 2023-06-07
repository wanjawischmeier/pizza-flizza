import 'package:firebase_database/firebase_database.dart';
import 'package:pizza_flizza/database/database.dart';

import 'item.dart';

/// userId, shopId
typedef OrderMap = Map<String, Map<String, Order>>;

/// fulfillerId, shopId, userId
typedef FulfilledMap = Map<String, Map<String, Map<String, Order>>>;

/// userId, shopId, timestamp
typedef HistoryMap = Map<String, Map<String, Map<int, HistoryOrder>>>;

class Order {
  String shopId, shopName;
  // itemId
  Map<String, OrderItem> items;

  double get price {
    double price = 0;

    for (var item in items.values) {
      price += item.price;
    }

    return price;
  }

  Order(
    this.shopId,
    this.shopName,
    this.items,
  );

  String get itemsFormatted {
    String result = '';
    if (items.isEmpty) {
      return result;
    }

    items.forEach((itemId, item) {
      result += '- ${item.count}x\t${item.itemName}\n';
    });

    return result.substring(0, result.length - 1);
  }
}

class FulfilledOrder extends Order {
  String fulfillerId, userId, fulfillerName, userName;
  String timeFormatted, dateFormatted;

  FulfilledOrder(
    this.fulfillerId,
    this.userId,
    super.shopId,
    super.shopName,
    this.fulfillerName,
    this.userName,
    this.timeFormatted,
    this.dateFormatted,
    super.items,
  );

  DatabaseReference get databaseReference =>
      Database.userReference.child('fulfilled/$shopId/$userId');

  /// itemId, count
  Map<String, int> get itemsParsed {
    var parsed = <String, int>{};

    items.forEach((itemId, item) {
      parsed[itemId] = item.count;
    });

    return parsed;
  }
}

class HistoryOrder {
  String shopId, shopName, timeFormatted, dateFormatted;

  /// itemId
  Map<String, HistoryItem> items;

  HistoryOrder(
    this.shopId,
    this.shopName,
    this.timeFormatted,
    this.dateFormatted,
    this.items,
  );

  HistoryOrder.fromFulfilledOrder(FulfilledOrder order)
      : shopId = order.shopId,
        shopName = order.shopName,
        timeFormatted = order.timeFormatted,
        dateFormatted = order.dateFormatted,
        items = order.items.map(
          (itemId, item) => MapEntry(
              itemId,
              HistoryItem(
                item.itemName,
                item.count,
                item.price,
              )),
        );

  // TODO: remove this mess in favor of inheritance
  double get price {
    double price = 0;

    for (var item in items.values) {
      price += item.price;
    }

    return price;
  }

  String get itemsFormatted {
    String result = '';
    if (items.isEmpty) {
      return result;
    }

    items.forEach((itemId, item) {
      result += '- ${item.count}x\t${item.itemName}\n';
    });

    return result.substring(0, result.length - 1);
  }
}
