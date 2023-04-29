import 'package:badges/badges.dart' as badges;
import 'package:cached_firestorage/lib.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pizza_flizza/theme.dart';

enum AppBarType { name, location }

typedef OnLocationChanged = void Function(String location);
typedef OnCartClicked = bool Function();

class DynamicAppBar extends StatefulWidget with PreferredSizeWidget {
  final String name;
  final AppBarType type;
  final ValueListenable<int> cartCount;
  final List<DropdownMenuItem<String>> items;
  final OnLocationChanged? onLocationChanged;
  final OnCartClicked? onCartClicked;

  const DynamicAppBar({
    super.key,
    required this.name,
    required this.type,
    required this.cartCount,
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
  String? _dropdownValue;
  late bool _showCartBadge;

  @override
  void initState() {
    _dropdownValue = widget.items.first.value;
    super.initState();
  }

  @override
  AppBar build(BuildContext context) {
    _showCartBadge = widget.cartCount.value > 0;
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
            value: _dropdownValue,
            items: widget.items,
            onChanged: (String? value) {
              if (value == null) return;
              setState(() => _dropdownValue = value);
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
            widget.cartCount.value.toString(),
            style: const TextStyle(color: Colors.white),
          ),
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: widget.onCartClicked,
            ),
          ),
        ),
      ],
    );
  }
}
