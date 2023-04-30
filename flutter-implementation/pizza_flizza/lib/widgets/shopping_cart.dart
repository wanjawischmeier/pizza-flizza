import 'package:flutter/material.dart';
import 'package:pizza_flizza/theme.dart';

typedef OnRemoveOverlay = void Function();

class ShoppingCart extends StatefulWidget {
  final OnRemoveOverlay onRemoveOverlay;

  const ShoppingCart({super.key, required this.onRemoveOverlay});

  @override
  State<ShoppingCart> createState() => _ShoppingCartState();
}

class _ShoppingCartState extends State<ShoppingCart> {
  final List<String> _orders = [
    'order0',
    'order1',
    'order2',
    'order3',
    'order4',
    'order5',
    'order6',
    'order7',
    'order8',
    'order9',
    'order10',
    'order11',
    'order12',
    'order13',
    'order14',
    'order15',
    'order16',
    'order17',
    'order18',
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: Themes.grayMid,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                  bottom: Radius.zero,
                ),
                child: Container(
                  color: Themes.grayLight,
                  padding: const EdgeInsets.all(16),
                  child: const Center(
                    child: Text(
                      'Your Orders',
                      style: TextStyle(
                        fontSize: 24,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _orders.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) {
                    String order = _orders[index];

                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Themes.grayMid,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Dismissible(
                              key: Key(order),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) {
                                setState(() {
                                  _orders.remove(order);
                                });
                              },
                              background: Container(
                                padding: const EdgeInsets.only(right: 16),
                                color: Themes.cream,
                                child: const Align(
                                  alignment: Alignment.centerRight,
                                  child: Icon(Icons.delete),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.only(left: 8),
                                title: Text(
                                    '$order\nesfesfaefa\nawefawefeaw\nadadsaa\nadawda'),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            decoration: BoxDecoration(
                              color: Themes.cream,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
