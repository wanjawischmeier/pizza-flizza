import 'dart:async';

import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';

import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/order.dart';
import 'package:pizza_flizza/database/shop.dart';
import 'package:pizza_flizza/theme.dart';

enum AppBarType { name, location }

typedef OnLocationChanged = void Function(String location);
typedef OnCartClicked = bool Function();

class DynamicAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String name;
  final AppBarType type;
  final List<DropdownMenuItem<String>> items;
  final OnLocationChanged? onLocationChanged;
  final OnCartClicked? onCartClicked;

  const DynamicAppBar({
    super.key,
    required this.name,
    required this.type,
    required this.items,
    this.onLocationChanged,
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
  late StreamSubscription<OrderMap> _ordersSubscription2;

  int countUserOrders(List<ShopItem> orders) {
    int count = 0;

    for (var item in orders) {
      if (item.userId == Database.userId) {
        count += item.count;
      }
    }

    return count;
  }

  @override
  void initState() {
    super.initState();

    _ordersSubscription2 = Shop.subscribeToOrdersUpdated2((orders) {
      _orderCount = 0;

      orders[Database.userId]?.forEach((shopId, order) {
        order.items.forEach((itemId, item) {
          _orderCount += item.count;
        });
      });

      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _ordersSubscription2.cancel();
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
            // iconEnabledColor: Themes.grayLight,
            dropdownColor: Themes.grayLight,
            // appBarTheme.titleTextStyle is null for some reason :/
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
