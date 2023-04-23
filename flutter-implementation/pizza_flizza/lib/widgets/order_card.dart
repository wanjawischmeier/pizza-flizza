import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pizza_flizza/theme.dart';

typedef OnCountChanged = bool Function(int count);

class OrderCardWidget extends StatefulWidget {
  final String itemId;
  final double price;
  final OnCountChanged onCountChanged;

  const OrderCardWidget({
    super.key,
    required this.itemId,
    required this.price,
    required this.onCountChanged,
  });

  @override
  State<OrderCardWidget> createState() => _OrderCardWidgetState();
}

class _OrderCardWidgetState extends State<OrderCardWidget> {
  int _itemCount = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Themes.grayMid,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: FutureBuilder(
              future: getItemImage(widget.itemId),
              builder: (BuildContext context, AsyncSnapshot<Image> snapshot) =>
                  snapshot.data ?? Text(widget.itemId),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                widget.itemId,
                textAlign: TextAlign.left,
              ),
            ],
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              NumberFormat.simpleCurrency(
                locale: 'de_DE', // Localizations.localeOf(context).scriptCode,
              ).format(widget.price),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            DefaultTextStyle(
              style: const TextStyle(fontSize: 25, color: Colors.white),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    MediaQuery.of(context).size.width / 2,
                  ),
                  color: Themes.grayLight,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _itemCount = max(0, min(99, _itemCount - 1));
                        });
                        widget.onCountChanged(_itemCount);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 16),
                        child: const Text('-'),
                      ),
                    ),
                    Container(
                      color: Themes.grayLight,
                      child: Text(
                        _itemCount.toString(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _itemCount = max(0, min(99, _itemCount + 1));
                        });
                        widget.onCountChanged(_itemCount);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 16),
                        child: const Text('+',
                            style: TextStyle(color: Themes.cream)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // based on: https://stackoverflow.com/a/71037750/13215204
  Future<Image> getItemImage(String path) async {
    try {
      await DefaultAssetBundle.of(context)
          .load('images/items/penny_burgtor/${widget.itemId}.png');
      return Image.asset('images/items/penny_burgtor/${widget.itemId}.png');
    } catch (_) {
      return const Image(
          image: AssetImage('images/items/penny_burgtor/baeckerkroenung.png'));
    }
  }
}
