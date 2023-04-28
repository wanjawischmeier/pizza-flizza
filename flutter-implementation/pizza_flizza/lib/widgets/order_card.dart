import 'package:cached_firestorage/remote_picture.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pizza_flizza/theme.dart';
import 'package:pizza_flizza/widgets/order_bubble.dart';

class OrderCardWidget extends StatefulWidget {
  final String itemId;
  final double price;
  final RemotePicture? image;
  final OnCountChanged onCountChanged;

  const OrderCardWidget({
    super.key,
    required this.itemId,
    required this.price,
    required this.image,
    required this.onCountChanged,
  });

  @override
  State<OrderCardWidget> createState() => _OrderCardWidgetState();
}

class _OrderCardWidgetState extends State<OrderCardWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Themes.grayMid,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: widget.image ?? const Text('not loaded'),
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
            Padding(
                padding: const EdgeInsets.only(top: 4),
                child: OrderBubbleWidget(onCountChanged: widget.onCountChanged))
          ]),
        ],
      ),
    );
  }
}
