import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/item.dart';
import 'package:pizza_flizza/database/shop.dart';

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
    this.items,
  ) : shopName = Shop.getShopName(shopId);

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
  String userId, fulfillerId, timeFormatted, dateFormatted;
  int timestamp;

  FulfilledOrder(
    this.userId,
    this.fulfillerId,
    super.shopId,
    this.timeFormatted,
    this.dateFormatted,
    this.timestamp,
    super.items,
  );

  FulfilledOrder.fromDate(
    String newFulfillerId,
    String newUserId,
    String newShopId,
    DateTime date,
    Map<String, OrderItem> items,
  )   : fulfillerId = newFulfillerId,
        userId = newUserId,
        timeFormatted = DateFormat.Hm().format(date),
        dateFormatted = DateFormat('dd.MM.yy').format(date),
        timestamp = date.millisecondsSinceEpoch,
        super(
          newShopId,
          items,
        );

  FulfilledOrder.fromUserItem(
    OrderItem item,
    String newUserId,
    DateTime date,
  )   : fulfillerId = newUserId,
        userId = newUserId,
        timeFormatted = DateFormat.Hm().format(date),
        dateFormatted = DateFormat('dd.MM.yy').format(date),
        timestamp = date.millisecondsSinceEpoch,
        super(
          item.shopId,
          {item.itemId: item},
        );

  DatabaseReference? get databaseReference =>
      Database.userReference?.child('fulfilled/$shopId/$userId');

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

  HistoryOrder operator +(HistoryOrder other) {
    Map<String, HistoryItem> newItems = Map.from(items);
    other.items.forEach((key, value) {
      var existing = newItems[key];

      if (existing == null) {
        newItems[key] = value;
      } else {
        newItems[key] = HistoryItem(
          existing.itemName,
          existing.count + value.count,
          existing.price + value.price,
        );
      }
    });

    return HistoryOrder(
      other.shopId,
      other.shopName,
      other.timeFormatted,
      other.dateFormatted,
      newItems,
    );
  }

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

  /// itemId, count
  Map<String, int> get itemsParsed {
    var parsed = <String, int>{};

    items.forEach((itemId, item) {
      parsed[itemId] = item.count;
    });

    return parsed;
  }
}
