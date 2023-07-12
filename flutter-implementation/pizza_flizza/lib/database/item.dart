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
    this.count,
    this.price,
  )   : shopName = Shop.getShopName(shopId),
        shopInfo = ShopItemInfo(shopId, itemId);
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
    super.count,
    super.price, {
    this.replacing = const {},
  });

  OrderItem.from(OrderItem order)
      : timestamp = order.timestamp,
        replacing = order.replacing,
        super(
          order.itemId,
          order.shopId,
          order.categoryId,
          order.userId,
          order.itemName,
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
    var itemInfo = ShopItemInfo(shopId, itemId);
    double price = count * itemInfo.price;

    // create instance
    return OrderItem(
      itemId,
      shopId,
      itemInfo.categoryId,
      userId,
      timestamp,
      itemInfo.itemName,
      count,
      price,
    );
  }
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

    var replacement = OrderItem.loadShopItem(
      userId,
      shopId,
      replacementId,
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
  String itemName;
  int count;
  double price;

  HistoryItem(
    this.itemName,
    this.count,
    this.price,
  );
}
