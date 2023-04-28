import 'package:flutter/material.dart';
import 'package:pizza_flizza/theme.dart';
import 'package:pizza_flizza/widgets/shopping_cart.dart';
import 'package:tuple/tuple.dart';
import 'package:pizza_flizza/fragments/order_fragment.dart';
import 'package:pizza_flizza/fragments/shop_fragment.dart';
import 'package:pizza_flizza/fragments/transaction_fragment.dart';
import 'package:pizza_flizza/widgets/dynamic_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  OverlayEntry? overlayEntry;
  int _selectedIndex = 0;
  final ValueNotifier<int> _cartCount = ValueNotifier<int>(0);
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

  static const List<DropdownMenuItem<String>> shops = [
    DropdownMenuItem(
      value: 'penny_burgtor',
      child: Text('Penny am Burgtor'),
    ),
  ];

  void createShoppingCartOverlay() {
    removeShoppingCartOverlay();
    assert(overlayEntry == null);

    // based on: https://stackoverflow.com/a/75487808/13215204
    overlayEntry = OverlayEntry(
      builder: (context) => SizedBox(
        child: Stack(
          children: [
            ModalBarrier(
              color: Themes.grayDark.withOpacity(0.5),
              onDismiss: () {
                removeShoppingCartOverlay();
              },
            ),
            Positioned(
              child: ShoppingCart(
                onRemoveOverlay: removeShoppingCartOverlay,
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry!);
  }

  void removeShoppingCartOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  @override
  void initState() {
    _bottomNavigationBarItems = List<BottomNavigationBarItem>.generate(
      _widgetOptions.length,
      (index) {
        var entry = _widgetOptions.entries.elementAt(index);
        return BottomNavigationBarItem(
            icon: Icon(entry.value.item1), label: entry.key);
      },
    );

    super.initState();
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
        cartCount: _cartCount,
        items: shops,
        onCartClicked: () {
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
