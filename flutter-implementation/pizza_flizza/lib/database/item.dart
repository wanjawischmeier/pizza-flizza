import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';

import 'database.dart';

class ShopItem {
  String itemId, shopId, userId, itemName, shopName;
  int count;
  double price;

  ShopItem(
    this.itemId,
    this.shopId,
    this.userId,
    this.itemName,
    this.shopName,
    this.count,
    this.price,
  );
}

class OrderItem extends ShopItem with EquatableMixin {
  int timestamp;

  DatabaseReference get databaseReference =>
      Database.userReference.child('orders/$shopId/$itemId');

  @override
  List<Object?> get props => [
        shopId,
        userId,
        timestamp,
        itemName,
        shopName,
        count,
        price,
      ];

  OrderItem(
    super.itemId,
    super.shopId,
    super.userId,
    this.timestamp,
    super.itemName,
    super.shopName,
    super.count,
    super.price,
  );

  OrderItem.copy(OrderItem order)
      : timestamp = order.timestamp,
        super(
          order.itemId,
          order.shopId,
          order.userId,
          order.itemName,
          order.shopName,
          order.count,
          order.price,
        );
}

class HistoryItem {
  String itemName;
  int count;
  double price;

  HistoryItem(
    this.itemName,
    this.count,
    this.price,
  );
}
