import 'dart:async';

import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:pizza_flizza/database.dart';
import 'package:pizza_flizza/theme.dart';

enum AppBarType { name, location }

typedef OnLocationChanged = void Function(String location);
typedef OnCartClicked = bool Function();

class DynamicAppBar extends StatefulWidget with PreferredSizeWidget {
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
  late StreamSubscription<List<ShopItem>> _openOrdersSubscription;

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

    _openOrdersSubscription = Shop.subscribeToOrderUpdated((orders) {
      setState(() {
        _orderCount = countUserOrders(orders);
      });
    });
    _orderCount = countUserOrders(Shop.openOrders);
  }

  @override
  void dispose() {
    super.dispose();
    _openOrdersSubscription.cancel();
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
            value: Shop.shopId,
            items: widget.items,
            onChanged: (String? value) {
              if (value == null) return;
              setState(() => Shop.shopId = value);
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
