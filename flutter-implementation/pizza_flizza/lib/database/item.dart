import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';

import 'database.dart';

class ShopItem2 {
  String itemId, shopId, userId, itemName, shopName;
  int count;
  double price;

  ShopItem2(
    this.itemId,
    this.shopId,
    this.userId,
    this.itemName,
    this.shopName,
    this.count,
    this.price,
  );
}

class OrderItem2 extends ShopItem2 with EquatableMixin {
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

  OrderItem2(
    super.itemId,
    super.shopId,
    super.userId,
    this.timestamp,
    super.itemName,
    super.shopName,
    super.count,
    super.price,
  );

  OrderItem2.copy(OrderItem2 order)
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
