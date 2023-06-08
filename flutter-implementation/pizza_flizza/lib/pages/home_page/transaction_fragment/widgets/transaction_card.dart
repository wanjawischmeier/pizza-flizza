import 'package:flutter/material.dart';

typedef OnDismiss = void Function(Object id);

class TransactionCardWidget extends StatelessWidget {
  static const double borderRadius = 8;

  final Color backgroundColor;
  final Color accentColor;
  final Object id;
  final String header, content, trailing;
  final Icon? icon;
  final bool dismissable;
  final OnDismiss? onDismiss;

  const TransactionCardWidget({
    super.key,
    required this.backgroundColor,
    required this.accentColor,
    required this.id,
    required this.header,
    required this.content,
    required this.trailing,
    this.icon,
    this.dismissable = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    var tile = Padding(
      padding: const EdgeInsets.all(borderRadius),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(bottom: borderRadius),
                  child: Text(
                    header,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    content,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: borderRadius * 2),
            child: Container(
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              padding: const EdgeInsets.all(borderRadius),
              child: Center(
                child: Text(
                  trailing,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
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
                    onDismissed: (direction) => onDismiss?.call(id),
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
