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
  String shopId;
  // itemId
  Map<String, OrderItem> items;

  double get price {
    double price = 0;

    for (var item in items.values) {
      price += item.price;
    }

    return price;
  }

  Order(this.shopId, this.items);

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
  /// itemId -> count
  Map<String, int> items;

  HistoryOrder(this.items);

  HistoryOrder.fromFulfilledOrder(FulfilledOrder order)
      : items = order.items.map(
          (itemId, item) => MapEntry(itemId, item.count),
        );
}
