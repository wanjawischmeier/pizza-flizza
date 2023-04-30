import 'package:flutter/material.dart';
import 'package:pizza_flizza/theme.dart';
import 'package:pizza_flizza/widgets/transaction_card.dart';

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
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(8),
                  bottom: Radius.zero,
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'Your Orders',
                            style: TextStyle(
                              fontSize: 24,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Themes.cream,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: Text(
                              'total',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    itemCount: _orders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      String order = _orders[index];

                      return TransactionCardWidget(
                        backgroundColor: Themes.grayLight,
                        accentColor: Themes.cream,
                        header: order,
                        content: '1x',
                        icon: const Icon(Icons.delete),
                        dismissable: true,
                        onDismiss: () {
                          setState(() {
                            _orders.remove(order);
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
