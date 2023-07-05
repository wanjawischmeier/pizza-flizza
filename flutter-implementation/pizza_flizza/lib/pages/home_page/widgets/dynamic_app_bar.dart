import 'dart:async';

import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';

import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/item.dart';
import 'package:pizza_flizza/database/order.dart';
import 'package:pizza_flizza/database/shop.dart';
import 'package:pizza_flizza/other/theme.dart';

enum AppBarType { name, location }

typedef OnLocationChanged = void Function(String location);
typedef OnActionClicked = bool Function();

class DynamicAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String name;
  final AppBarType type;
  final List<DropdownMenuItem<String>> items;
  final OnLocationChanged? onLocationChanged;
  final OnActionClicked? onProfileClicked, onCartClicked;

  const DynamicAppBar({
    super.key,
    required this.name,
    required this.type,
    required this.items,
    this.onLocationChanged,
    this.onProfileClicked,
    this.onCartClicked,
  });

  @override
  State<DynamicAppBar> createState() => _DynamicAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _DynamicAppBarState extends State<DynamicAppBar> {
  late bool _showCartBadge;
  int _orderCount = 0;
  late StreamSubscription<OrderMap> _ordersSubscription;

  int countUserOrders(List<ShopItem> orders) {
    int count = 0;
    var user = Database.currentUser;
    if (user == null) {
      return -1;
    }

    for (var item in orders) {
      if (item.userId == user.userId) {
        count += item.count;
      }
    }

    return count;
  }

  @override
  void initState() {
    super.initState();

    var user = Database.currentUser;
    if (user == null) {
      return;
    }

    _ordersSubscription = Shop.subscribeToOrdersUpdated((orders) {
      _orderCount = 0;

      orders[user.userId]?.forEach((shopId, order) {
        order.items.forEach((itemId, item) {
          _orderCount += item.count;
        });
      });

      setState(() {});
    });
  }

  @override
  void dispose() {
    _ordersSubscription.cancel();
    super.dispose();
  }

  @override
  AppBar build(BuildContext context) {
    _showCartBadge = _orderCount > 0;
    Widget child;

    switch (widget.type) {
      case AppBarType.location:
        child = DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            focusColor: Themes.grayMid,
            dropdownColor: Themes.grayLight,
            style: Theme.of(context).textTheme.titleLarge,
            value: Shop.currentShopId,
            items: widget.items,
            onChanged: (String? value) {
              if (value == null) return;
              setState(() => Shop.currentShopId = value);
            },
          ),
        );
        break;
      default:
        child = Text(widget.name);
        break;
    }

    return AppBar(
      title: child,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.account_box),
          onPressed: widget.onProfileClicked,
        ),
        badges.Badge(
          position: badges.BadgePosition.topEnd(top: 4, end: 4),
          badgeAnimation: const badges.BadgeAnimation.slide(),
          showBadge: _showCartBadge,
          badgeStyle: const badges.BadgeStyle(
            badgeColor: Themes.grayLight,
          ),
          badgeContent: Text(
            _orderCount.toString(),
            style: const TextStyle(color: Colors.white),
          ),
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: (_orderCount == 0) ? null : widget.onCartClicked,
            ),
          ),
        ),
      ],
    );
  }
}
