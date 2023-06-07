import 'package:cached_firestorage/lib.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import 'package:pizza_flizza/database/shop.dart';
import 'package:pizza_flizza/theme.dart';
import 'package:pizza_flizza/widgets/shopping_cart.dart';
import 'package:pizza_flizza/fragments/order_fragment.dart';
import 'package:pizza_flizza/fragments/shop_fragment.dart';
import 'package:pizza_flizza/fragments/transaction_fragment.dart';
import 'package:pizza_flizza/widgets/dynamic_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  static const Duration _cartAnimationDurationIn = Duration(milliseconds: 300);
  static const Duration _cartAnimationDurationOut = Duration(milliseconds: 150);
  late AnimationController _controller;
  late final Animation<double> _opacityAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCirc,
  );

  OverlayEntry? _overlayEntry;
  int _selectedIndex = 0;
  late List<BottomNavigationBarItem> _bottomNavigationBarItems;

  static const Map<String, Tuple3<IconData, AppBarType, Widget>>
      _widgetOptions = {
    'Order': Tuple3(
      Icons.online_prediction_rounded,
      AppBarType.location,
      OrderFragment(),
    ),
    'Shop': Tuple3(
      Icons.shop_2,
      AppBarType.location,
      ShopFragment(),
    ),
    'Transactions': Tuple3(
      Icons.transcribe_sharp,
      AppBarType.name,
      TransactionFragment(),
    ),
  };

  List<DropdownMenuItem<String>> shops =
      List.generate(Shop.shops.length, (index) {
    var shop = Shop.shops.entries.elementAt(index);
    String shopId = shop.key;

    return DropdownMenuItem(
      value: shopId,
      child: Row(
        children: [
          Center(
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              child: AspectRatio(
                aspectRatio: 1,
                child: RemotePicture(
                  imagePath: '/shops/$shopId/logo.png',
                  mapKey: '${shopId}_logo',
                  useAvatarView: true,
                  avatarViewRadius: 8,
                ),
              ),
            ),
          ),
          Text(shop.value['name'], style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  });

  void createShoppingCartOverlay() {
    removeShoppingCartOverlay();

    // based on: https://stackoverflow.com/a/75487808/13215204
    _overlayEntry = OverlayEntry(
      builder: (context) => SizedBox(
        child: Stack(
          children: [
            FadeTransition(
              opacity: _opacityAnimation,
              child: ModalBarrier(
                color: Themes.grayDark.withOpacity(0.5),
                onDismiss: () {
                  removeShoppingCartOverlay();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 40),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 0.6,
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _controller,
                      curve: const ElasticOutCurve(1),
                      reverseCurve: Curves.easeOut,
                    ),
                    child: ShoppingCart(
                      onRemoveOverlay: removeShoppingCartOverlay,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _controller.forward();
  }

  void removeShoppingCartOverlay() {
    if (_overlayEntry == null) {
      return;
    }

    _controller.reverse();

    Future.delayed(_cartAnimationDurationOut, () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _cartAnimationDurationIn,
      reverseDuration: _cartAnimationDurationOut,
    );

    _bottomNavigationBarItems = List<BottomNavigationBarItem>.generate(
      _widgetOptions.length,
      (index) {
        var entry = _widgetOptions.entries.elementAt(index);
        return BottomNavigationBarItem(
            icon: Icon(entry.value.item1), label: entry.key);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var entry = _widgetOptions.entries.elementAt(_selectedIndex);
    var name = entry.key;
    var type = entry.value.item2;
    var widget = entry.value.item3;

    return Scaffold(
      appBar: DynamicAppBar(
        name: name,
        type: type,
        items: shops,
        onCartClicked: () {
          /*
          if (FirebaseAuth.instance.currentUser != null) {
            FirebaseAuth.instance.signOut();
          }
          */

          createShoppingCartOverlay();
          return true;
        },
      ),
      body: Center(
        child: widget,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomNavigationBarItems,
        currentIndex: _selectedIndex,
        onTap: (value) {
          setState(() {
            _selectedIndex = value;
          });
        },
      ),
    );
  }
}
