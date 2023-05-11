import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pizza_flizza/helper.dart';
import 'package:pizza_flizza/theme.dart';
import 'package:pizza_flizza/widgets/cached_remote_picture.dart';
import 'package:pizza_flizza/widgets/order_bubble.dart';

class OrderCardWidget extends StatefulWidget {
  final String categoryId, itemId, name;
  final double price;
  final OnCountChanged onCountChanged;

  const OrderCardWidget({
    super.key,
    required this.categoryId,
    required this.itemId,
    required this.name,
    required this.price,
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
            child: RemoteItemImage(itemId: widget.itemId),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  widget.name,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              Helper.formatPrice(widget.price),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: OrderBubbleWidget(
                categoryId: widget.categoryId,
                itemId: widget.itemId,
                onCountChanged: widget.onCountChanged,
              ),
            )
          ]),
        ],
      ),
    );
  }
}
