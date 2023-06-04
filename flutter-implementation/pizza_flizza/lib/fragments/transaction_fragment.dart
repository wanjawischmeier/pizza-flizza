import 'package:flutter/material.dart';
import 'package:pizza_flizza/theme.dart';
import 'package:pizza_flizza/widgets/transaction_card.dart';

enum OrderType { ordered, fulfilled }

class TransactionFragment extends StatefulWidget {
  const TransactionFragment({super.key});

  @override
  State<TransactionFragment> createState() => _TransactionFragmentState();
}

class _TransactionFragmentState extends State<TransactionFragment> {
  final Map<String, OrderType> _orders = {
    'order0': OrderType.ordered,
    'order1': OrderType.fulfilled,
    'order2': OrderType.fulfilled,
    'order3': OrderType.ordered,
    'order4': OrderType.ordered,
    'order5': OrderType.fulfilled,
    'order6': OrderType.fulfilled,
    'order7': OrderType.ordered,
    'order8': OrderType.fulfilled,
  };

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: _orders.length,
      padding: const EdgeInsets.all(8),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        var order = _orders.entries.elementAt(index);
        bool dismissable;
        Color color;
        IconData? iconData;

        switch (order.value) {
          case OrderType.ordered:
            dismissable = false;
            color = Themes.cream;
            break;
          case OrderType.fulfilled:
            dismissable = true;
            color = Themes.grayLight;
            iconData = Icons.check;
            break;
        }

        return TransactionCardWidget(
          backgroundColor: Themes.grayMid,
          accentColor: color,
          id: order.key,
          header: order.key,
          content:
              '1x adadwwdad\n2x sadads\n3x asfasdsdawda\n4x adwdfa\n5x awdwa',
          trailing: '9.99 §',
          icon: Icon(iconData),
          dismissable: dismissable,
          onDismiss: (orderId) {
            setState(() {
              _orders.remove(orderId);
            });
          },
        );
      },
    );
  }
}
