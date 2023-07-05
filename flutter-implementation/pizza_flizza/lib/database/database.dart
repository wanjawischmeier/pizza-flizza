import 'dart:core';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pizza_flizza/database/item.dart';

import 'user.dart';

class Database {
  static var storage = FirebaseStorage.instance.ref();
  static var realtime = FirebaseDatabase.instance.ref();

  static const String imageResolution = '256px';
  static Map<String, String> groupUsers = {};
  static UserStats? currentStats;
  static UserData? currentUser;

  static String? getUserName(String userId) {
    return groupUsers[userId];
  }

  static DatabaseReference? get groupReference {
    var user = currentUser;
    if (user == null) {
      return null;
    }

    return Database.realtime.child('groups/${user.group.groupId}');
  }

  static DatabaseReference? get userReference {
    var user = currentUser;
    if (user == null) {
      return null;
    }

    return Database.realtime.child(
      'users/${user.group.groupId}/${user.userId}',
    );
  }

  static DatabaseReference? getOrderItemReference(ShopItem item) {
    return userReference?.child('orders/${item.shopId}/${item.itemId}');
  }
}
