import 'item.dart';

/// userId, shopId
typedef OrderMap = Map<String, Map<String, Order2>>;

/// fulfillerId, shopId, userId
typedef FulfilledMap = Map<String, Map<String, Map<String, Order2>>>;

/// userId, shopId
typedef HistoryMap = Map<String, Map<String, FulfilledOrder2>>;

class Order2 {
  // itemId
  Map<String, OrderItem2> items;

  double get price {
    double price = 0;

    for (var item in items.values) {
      price += item.price;
    }

    return price;
  }

  Order2(this.items);
}

class FulfilledOrder2 {
  String fulfillerId, userId, fulfillerName, userName;
  String timeFormatted, dateFormatted;
  double price;
  Map<String, OrderItem2> items;

  FulfilledOrder2(
    this.fulfillerId,
    this.userId,
    this.fulfillerName,
    this.userName,
    this.timeFormatted,
    this.dateFormatted,
    this.price,
    this.items,
  );
}
