import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import '../fragments/order_fragment.dart';
import '../fragments/shop_fragment.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;

  static const Map<String, Tuple2<IconData, Widget>> _widgetOptions =
      <String, Tuple2<IconData, Widget>>{
    'Order': Tuple2(Icons.online_prediction_rounded, OrderFragment()),
    'Shop': Tuple2(Icons.shop_2, ShopFragment()),
  };

  @override
  Widget build(BuildContext context) {
    var entry = _widgetOptions.entries.elementAt(_selectedIndex);
    String name = entry.key;
    Icon icon = Icon(entry.value.item1);
    Widget widget = entry.value.item2;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: Center(
        child: widget,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: List<BottomNavigationBarItem>.generate(
          _widgetOptions.length,
          (index) => BottomNavigationBarItem(icon: icon, label: name),
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
