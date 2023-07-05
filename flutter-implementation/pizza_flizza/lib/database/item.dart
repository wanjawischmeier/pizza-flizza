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
  String itemId, shopId, userId, itemName, shopName;
  int count;
  double price;
  ShopItemInfo shopInfo;

  ShopItem(
    this.itemId,
    this.shopId,
    this.userId,
    this.itemName,
    this.shopName,
    this.count,
    this.price,
  ) : shopInfo = ShopItemInfo(shopId, itemId);
}

class OrderItem extends ShopItem with EquatableMixin {
  int timestamp;

  DatabaseReference? get databaseReference {
    var user = Database.currentUser;
    if (user == null) {
      return null;
    }

    return Database.realtime.child(
      'users/${user.group.groupId}/${user.userId}/orders/$shopId/$itemId',
    );
  }

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

extension ItemFilter on Iterable<OrderItem> {
  /// get all matching items.
  /// NOT considering item counts.
  OrderItem? getMatchingItem(OrderItem item) {
    return where(
      (orderItem) =>
          orderItem.userId == item.userId && orderItem.shopId == item.shopId,
    ).firstOrNull;
  }

  int get totalItemCount {
    int count = 0;

    for (var item in this) {
      count += item.count;
    }

    return count;
  }
}

extension ItemMatch on OrderItem? {
  bool identityMatches(OrderItem? item) {
    return this?.itemId == item?.itemId && this?.shopId == item?.shopId;
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
