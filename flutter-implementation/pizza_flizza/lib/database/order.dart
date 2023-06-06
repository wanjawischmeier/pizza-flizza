import 'package:firebase_database/firebase_database.dart';
import 'package:pizza_flizza/database/database.dart';

import 'item.dart';

/// userId, shopId
typedef OrderMap = Map<String, Map<String, Order2>>;

/// fulfillerId, shopId, userId
typedef FulfilledMap = Map<String, Map<String, Map<String, Order2>>>;

/// userId, shopId, timestamp
typedef HistoryMap = Map<String, Map<String, Map<int, HistoryOrder2>>>;

class Order2 {
  String shopId;
  // itemId
  Map<String, OrderItem2> items;

  double get price {
    double price = 0;

    for (var item in items.values) {
      price += item.price;
    }

    return price;
  }

  Order2(this.shopId, this.items);

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

class FulfilledOrder2 extends Order2 {
  String fulfillerId, userId, fulfillerName, userName;
  String timeFormatted, dateFormatted;

  FulfilledOrder2(
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

class HistoryOrder2 {
  /// itemId -> count
  Map<String, int> items;

  HistoryOrder2(this.items);

  HistoryOrder2.fromFulfilledOrder(FulfilledOrder2 order)
      : items = order.items.map(
          (itemId, item) => MapEntry(itemId, item.count),
        );
}
