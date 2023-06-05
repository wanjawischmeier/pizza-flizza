import 'dart:core';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ShopItem {
  String id, shopId, userId, name, shopName;
  int count;
  double price;
  DatabaseReference get databaseReference =>
      Database.userReference.child('orders/$shopId/$id');

  ShopItem(
    this.id,
    this.shopId,
    this.userId,
    this.name,
    this.shopName,
    this.count,
    this.price,
  );

  static ShopItem? getById(List<ShopItem> orders, String id) {
    var matching = orders.where((order) => order.id == id);
    return matching.isEmpty ? null : matching.first;
  }
}

class OpenItem extends ShopItem {
  int timestamp;

  OpenItem(
    super.id,
    super.shopId,
    super.userId,
    this.timestamp,
    super.name,
    super.shopName,
    super.count,
    super.price,
  );

  OpenItem.fromNow(ShopItem shopItem)
      : timestamp = DateTime.now().millisecondsSinceEpoch,
        super(
          shopItem.id,
          shopItem.shopId,
          shopItem.userId,
          shopItem.name,
          shopItem.shopName,
          shopItem.count,
          shopItem.price,
        );
}

class FulfilledItem extends OpenItem {
  String fulfillerId;

  FulfilledItem(
    super.id,
    super.shopId,
    super.userId,
    this.fulfillerId,
    super.name,
    super.shopName,
    super.count,
    super.price,
    super.timestamp,
  );

  FulfilledItem.fromOpenNow(OpenItem openItem, this.fulfillerId)
      : super(
          openItem.id,
          openItem.shopId,
          openItem.userId,
          DateTime.now().millisecondsSinceEpoch,
          openItem.name,
          openItem.shopName,
          openItem.count,
          openItem.price,
        );

  static FulfilledItem? getById(List<FulfilledItem> orders, String id) {
    var matching = orders.where((order) => order.id == id);
    return matching.isEmpty ? null : matching.first;
  }
}

class Database {
  static var storage = FirebaseStorage.instance.ref();
  static var realtime = FirebaseDatabase.instance.ref();

  static late String groupId, userId;
  static String? userName;

  static DatabaseReference get groupReference =>
      Database.realtime.child('users/${Database.groupId}');
  static DatabaseReference get userReference =>
      Database.realtime.child('users/${Database.groupId}/${Database.userId}');

  static DatabaseReference getOrderItemReference(ShopItem item) {
    return userReference.child('orders/${item.shopId}/${item.id}');
  }

  static Future<String> getUserName(String userId) {
    return Database.realtime
        .child('users/${Database.groupId}/$userId/name')
        .get()
        .then((snapshot) {
      if (snapshot.value != null) {
        return snapshot.value as String;
      } else {
        return 'Unknown Username';
      }
    });
  }
}
