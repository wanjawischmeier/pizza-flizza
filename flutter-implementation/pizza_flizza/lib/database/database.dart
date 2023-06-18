import 'dart:core';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pizza_flizza/database/item.dart';

class Database {
  static var storage = FirebaseStorage.instance.ref();
  static var realtime = FirebaseDatabase.instance.ref();

  static const String imageResolution = '256px';
  static String? userId, userName, userEmail, providerId, groupName;
  static int? groupId;

  static DatabaseReference get groupReference =>
      Database.realtime.child('users/${Database.groupId}');
  static DatabaseReference get userReference =>
      Database.realtime.child('users/${Database.groupId}/${Database.userId}');

  static DatabaseReference getOrderItemReference(ShopItem item) {
    return userReference.child('orders/${item.shopId}/${item.itemId}');
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
