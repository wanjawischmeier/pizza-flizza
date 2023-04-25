import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pizza_flizza/theme.dart';
import 'package:pizza_flizza/widgets/order_bubble.dart';

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
  static const String basePath = 'assets/images/items/penny_burgtor';

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
            Padding(
                padding: const EdgeInsets.only(top: 4),
                child: OrderBubbleWidget(onCountChanged: widget.onCountChanged))
          ]),
        ],
      ),
    );
  }

  // based on: https://stackoverflow.com/a/71037750/13215204
  Future<Image> getItemImage(String path) async {
    try {
      await DefaultAssetBundle.of(context)
          .load('$basePath/${widget.itemId}.png');
      return Image.asset('$basePath/${widget.itemId}.png');
    } catch (_) {
      return const Image(image: AssetImage('$basePath/baeckerkroenung.png'));
    }
  }
}
