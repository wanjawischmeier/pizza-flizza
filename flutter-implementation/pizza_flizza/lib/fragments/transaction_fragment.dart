import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pizza_flizza/theme.dart';

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
        bool removable;
        Color color;
        IconData? iconData;

        switch (order.value) {
          case OrderType.ordered:
            removable = false;
            color = Themes.cream;
            break;
          case OrderType.fulfilled:
            removable = true;
            color = Themes.grayLight;
            iconData = Icons.check;
            break;
        }

        var tile = ListTile(
          contentPadding: const EdgeInsets.only(left: 8),
          title: Text(
            '${order.key}\ndsdsdsd\nsadads\nasfasdsdawda\nadwdfa\nawdwa',
          ),
        );

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Themes.grayMid,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: removable
                    ? Dismissible(
                        key: Key(order.key),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          setState(() {
                            _orders.remove(order.key);
                          });
                        },
                        background: Container(
                          padding: const EdgeInsets.only(right: 16),
                          color: color,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Icon(iconData),
                          ),
                        ),
                        child: tile,
                      )
                    : tile,
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: Container(
                width: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
