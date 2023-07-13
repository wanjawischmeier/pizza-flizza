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

  Order.from(Order order)
      : shopId = order.shopId,
        shopName = order.shopName,
        items = Map.from(order.items);

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
  String userId, fulfillerId;
  DateTime date;

  FulfilledOrder(
    this.fulfillerId,
    this.userId,
    super.shopId,
    this.date,
    super.items,
  );

  FulfilledOrder.fromUserItem(
    this.userId,
    this.date,
    OrderItem item,
  )   : fulfillerId = userId,
        super(
          item.shopId,
          {item.itemId: item},
        );

  DatabaseReference? get databaseReference =>
      Database.userReference?.child('fulfilled/$shopId/$userId');

  /// itemId -> count
  Map<String, int> get itemsParsed {
    var parsed = <String, int>{};

    items.forEach((itemId, item) {
      parsed[itemId] = item.count;
    });

    return parsed;
  }

  int get timestamp => date.millisecondsSinceEpoch;

  String get timeFormatted => DateFormat.Hm().format(date);

  String get dateFormatted => DateFormat('dd.MM.yy').format(date);
}

class HistoryOrder {
  String shopId, shopName;
  DateTime date;

  /// itemId
  Map<String, HistoryItem> items;

  HistoryOrder(
    this.shopId,
    this.date,
    this.items,
  ) : shopName = Shop.getShopName(shopId);

  HistoryOrder.fromFulfilledOrder(FulfilledOrder order)
      : shopId = order.shopId,
        shopName = order.shopName,
        date = order.date,
        items = order.items.map(
          (itemId, item) => MapEntry(
            itemId,
            HistoryItem(
              item.itemId,
              item.itemName,
              item.count,
              item.price,
            ),
          ),
        );

  HistoryOrder operator +(HistoryOrder other) {
    Map<String, HistoryItem> newItems = Map.from(items);
    other.items.forEach((key, value) {
      var existing = newItems[key];

      if (existing == null) {
        newItems[key] = value;
      } else {
        newItems[key] = HistoryItem(
          existing.itemId,
          existing.itemName,
          existing.count + value.count,
          existing.price + value.price,
        );
      }
    });

    return HistoryOrder(
      other.shopId,
      other.date,
      newItems,
    );
  }

  int get timestamp => date.millisecondsSinceEpoch;

  String get timeFormatted => DateFormat.Hm().format(date);

  String get dateFormatted => DateFormat('dd.MM.yy').format(date);

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
  Map<String, int> get json {
    var parsed = <String, int>{};

    items.forEach((itemId, item) {
      parsed[itemId] = item.count;
    });

    return parsed;
  }
}
