import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pizza_flizza/database/orders/orders.dart';
import 'package:pizza_flizza/database/shop.dart';

import 'database.dart';

class ShopItemInfo {
  final String _shopId;
  final Map _info;

  int get bought => _info['bought'];
  double get price => _info['price'];
  String get itemName => _info['name'];
  String get shopName => Shop.getShopName(_shopId);
  String get categoryId => _info['categoryId'];

  set bought(int value) => _info['bought'] = value;

  ShopItemInfo(String shopId, String itemId)
      : _shopId = shopId,
        _info = Shop.getItemInfo(shopId, itemId);
}

class ShopItem {
  String itemId, shopId, userId, shopName;
  int count;

  final ShopItemInfo _shopInfo;

  String get categoryId => _shopInfo.categoryId;

  String get itemName => _shopInfo.itemName;

  double get price => count * _shopInfo.price;

  int get bought => _shopInfo.bought;
  set bought(value) => _shopInfo.bought = value;

  ShopItem(
    this.itemId,
    this.shopId,
    this.userId,
    this.count,
  )   : shopName = Shop.getShopName(shopId),
        _shopInfo = ShopItemInfo(shopId, itemId);
}

class OrderItem extends ShopItem with EquatableMixin {
  int timestamp;
  Map<String, int> replacing;

  DatabaseReference? get databaseReference {
    var user = Database.currentUser;
    if (user == null) {
      return null;
    }

    return Database.realtime.child(
      'users/${user.group.groupId}/$userId/orders/$shopId/$itemId',
    );
  }

  DatabaseReference get shopReference => Database.realtime
      .child('shops/$shopId/items/${_shopInfo.categoryId}/$itemId');

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
    super.count, {
    this.replacing = const {},
  });

  OrderItem.from(OrderItem item)
      : timestamp = item.timestamp,
        replacing = item.replacing,
        super(
          item.itemId,
          item.shopId,
          item.userId,
          item.count,
        );
}

extension ItemFilter on OrderItem {
  OrderItem? get replacement {
    // get favourite, if possible from user
    var userFavourites = Orders.stats[userId]?[shopId]?[categoryId]?.keys;
    var globalFavourites = Shop.stats[categoryId]?.keys;
    var replacementId = userFavourites?.firstOrNull;
    replacementId ??= globalFavourites?.firstOrNull;

    if (replacementId == itemId) {
      replacementId = userFavourites?.elementAtOrNull(1);

      if (replacementId == null) {
        replacementId = globalFavourites?.firstOrNull;

        if (replacementId == itemId) {
          replacementId = globalFavourites?.elementAtOrNull(0);
        }
      }
    }

    if (replacementId == null) {
      return null;
    }

    var replacement = OrderItem(
      replacementId,
      shopId,
      userId,
      timestamp,
      count,
    );
    return replacement;
  }
}

extension NullableItemFilter on OrderItem? {
  bool identityMatches(OrderItem? item) {
    return this?.itemId == item?.itemId && this?.shopId == item?.shopId;
  }
}

extension IterableItemFilter on Iterable<OrderItem> {
  /// get all matching items.
  /// NOT considering item counts.
  OrderItem? getMatchingItem(OrderItem item) {
    return where(
      (orderItem) =>
          orderItem.userId == item.userId && orderItem.shopId == item.shopId,
    ).firstOrNull;
  }

  Iterable<OrderItem> getMatchingId(String itemId) {
    return where((element) => element.itemId == itemId);
  }

  int get totalItemCount {
    int count = 0;

    for (var item in this) {
      count += item.count;
    }

    return count;
  }
}

class HistoryItem {
  String itemId, itemName;
  int count;
  double price;

  HistoryItem(
    this.itemId,
    this.itemName,
    this.count,
    this.price,
  );
}
