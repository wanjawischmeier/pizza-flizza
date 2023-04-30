import 'package:flutter/material.dart';
import 'package:pizza_flizza/theme.dart';

typedef OnDismiss = void Function();

class TransactionCardWidget extends StatelessWidget {
  static const double borderRadius = 8;

  final Color backgroundColor;
  final Color accentColor;
  final String header;
  final String content;
  final Icon icon;
  final bool dismissable;
  final OnDismiss? onDismiss;

  const TransactionCardWidget({
    super.key,
    required this.backgroundColor,
    required this.accentColor,
    required this.header,
    required this.content,
    required this.icon,
    this.dismissable = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    var tile = ListTile(
      contentPadding: const EdgeInsets.only(left: borderRadius),
      title: SizedBox(
        height: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(header),
            ),
            Flexible(
              child: Text(
                'date',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      subtitle: Text(content),
      trailing: Padding(
        padding: const EdgeInsets.only(right: borderRadius * 4),
        child: AspectRatio(
          aspectRatio: 2,
          child: Container(
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: EdgeInsets.zero,
            child: Center(
              child: Text(
                'price',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: backgroundColor,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: dismissable
                ? Dismissible(
                    key: Key(header),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) => onDismiss?.call(),
                    background: Container(
                      padding: const EdgeInsets.only(right: borderRadius * 2),
                      color: accentColor,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: icon,
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
            width: borderRadius * 2,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        ),
      ],
    );
  }
}
