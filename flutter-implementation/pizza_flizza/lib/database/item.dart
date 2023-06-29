import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pizza_flizza/database/shop.dart';

import 'database.dart';

class ShopItemInfo {
  final Map _info;

  int get bought => _info['bought'];
  double get price => _info['price'];
  String get itemName => _info['name'];
  String get categoryId => _info['category'];

  set bought(int value) => _info['bought'] = value;

  ShopItemInfo(String shopId, String itemId)
      : _info = Shop.getItemInfo(shopId, itemId);
}

class ShopItem {
  String itemId, shopId, userId, userName, itemName, shopName;
  int count;
  double price;
  ShopItemInfo shopInfo;

  ShopItem(
    this.itemId,
    this.shopId,
    this.userId,
    this.userName,
    this.itemName,
    this.shopName,
    this.count,
    this.price,
  ) : shopInfo = ShopItemInfo(shopId, itemId);
}

class OrderItem extends ShopItem with EquatableMixin {
  int timestamp;

  DatabaseReference get databaseReference => Database.realtime
      .child('users/${Database.groupId}/$userId/orders/$shopId/$itemId');

  DatabaseReference get shopReference => Database.realtime
      .child('shops/$shopId/items/${shopInfo.categoryId}/$itemId');

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
    super.userName,
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
          order.userName,
          order.itemName,
          order.shopName,
          order.count,
          order.price,
        );
}

extension ItemFilter on Iterable<OrderItem> {
  /// checks whether the given iterable contains an item.
  /// NOT considering item counts.
  bool containsItem(OrderItem item) {
    return where(
      (orderItem) =>
          orderItem.userId == item.userId && orderItem.shopId == item.shopId,
    ).isNotEmpty;
  }

  OrderItem? getMatchingItem(OrderItem item) {
    return where(
      (orderItem) =>
          orderItem.userId == item.userId && orderItem.shopId == item.shopId,
    ).firstOrNull;
  }
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
