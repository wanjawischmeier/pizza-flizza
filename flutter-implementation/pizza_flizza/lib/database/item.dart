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
  String itemId, shopId, categoryId, userId, itemName, shopName;
  int count;
  double price;
  ShopItemInfo shopInfo;

  ShopItem(
    this.itemId,
    this.shopId,
    this.categoryId,
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
    super.categoryId,
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
          order.categoryId,
          order.userId,
          order.itemName,
          order.shopName,
          order.count,
          order.price,
        );

  static OrderItem loadShopItem(
    String userId,
    String shopId,
    String itemId,
    int timestamp,
    int count,
  ) {
    // get item info
    var itemInfo = Shop.getItemInfo(shopId, itemId);
    String shopName = Shop.getShopName(shopId);
    String itemName = itemInfo['name'];
    String categoryId = itemInfo['categoryId'];
    double price = count * (itemInfo['price'] as double);

    // create instance
    return OrderItem(
      itemId,
      shopId,
      categoryId,
      userId,
      timestamp,
      itemName,
      shopName,
      count,
      price,
    );
  }
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
