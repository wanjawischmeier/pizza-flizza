import 'package:flutter/material.dart';
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
  int _selectedIndex = 1;
  final ValueNotifier<int> _cartCount = ValueNotifier<int>(0);

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

  @override
  Widget build(BuildContext context) {
    var entry = _widgetOptions.entries.elementAt(_selectedIndex);
    var name = entry.key;
    var type = entry.value.item2;
    var widget = entry.value.item3;

    List<DropdownMenuItem<String>> shops = const [
      DropdownMenuItem(
        value: 'penny_burgtor',
        child: Text('Penny am Burgtor'),
      ),
    ];

    return Scaffold(
      appBar: DynamicAppBar(
        name: name,
        type: type,
        cartCount: _cartCount,
        items: shops,
        onCartClicked: () {
          setState(() {
            _cartCount.value++;
          });
          return true;
        },
      ),
      body: Center(
        child: widget,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: List<BottomNavigationBarItem>.generate(
          _widgetOptions.length,
          (index) {
            var entry = _widgetOptions.entries.elementAt(index);
            return BottomNavigationBarItem(
                icon: Icon(entry.value.item1), label: entry.key);
          },
        ),
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
