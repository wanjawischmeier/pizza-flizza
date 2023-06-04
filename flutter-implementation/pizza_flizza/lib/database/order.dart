import 'item.dart';

typedef OrderMap = Map<String, Map<String, Order2>>;
typedef FulfilledMap = Map<String, Map<String, Map<String, Order2>>>;
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
  String fulfillerId;
  int timestamp;
  double price;
  Map<String, OrderItem2> items;

  FulfilledOrder2(
    this.fulfillerId,
    this.timestamp,
    this.price,
    this.items,
  );
  /*
  FulfilledOrder2.fromOpenNow(Order2 order, this.fulfillerId)
      : timestamp = DateTime.now().millisecondsSinceEpoch,
        price = order.price,
        items = order.items;
  */
}
