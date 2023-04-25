import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pizza_flizza/theme.dart';

typedef OnCountChanged = bool Function(int count);

class OrderBubbleWidget extends StatefulWidget {
  final OnCountChanged onCountChanged;

  const OrderBubbleWidget({super.key, required this.onCountChanged});

  @override
  State<OrderBubbleWidget> createState() => _OrderBubbleWidgetState();
}

class _OrderBubbleWidgetState extends State<OrderBubbleWidget> {
  int _itemCount = 0;
  final TextPainter _addTextPainter = TextPainter(
      text: const TextSpan(text: '+', style: TextStyle(fontSize: 14)),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr)
    ..layout(minWidth: 0, maxWidth: double.infinity);
  final TextPainter _countTextPainter = TextPainter(
      text: const TextSpan(text: '999', style: TextStyle(fontSize: 14)),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr)
    ..layout(minWidth: 0, maxWidth: double.infinity);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Themes.grayLight,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(MediaQuery.of(context).size.width / 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(MediaQuery.of(context).size.width / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 25, color: Colors.white),
          child: Row(
            children: [
              InkWell(
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    MediaQuery.of(context).size.height / 2,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _itemCount = max(0, min(99, _itemCount - 1));
                  });
                  widget.onCountChanged(_itemCount);
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SizedBox(
                    width: _addTextPainter.height,
                    height: _addTextPainter.height,
                    child: const FittedBox(
                      fit: BoxFit.fill,
                      child: Text('-'),
                    ),
                  ),
                ),
              ),
              Container(
                width: _countTextPainter.width,
                padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                child: Text(
                  _itemCount.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
              InkWell(
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    MediaQuery.of(context).size.width / 2,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _itemCount = max(0, min(99, _itemCount + 1));
                  });
                  widget.onCountChanged(_itemCount);
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SizedBox(
                    width: _addTextPainter.height,
                    height: _addTextPainter.height,
                    child: const FittedBox(
                      fit: BoxFit.cover,
                      child: Text('+', style: TextStyle(color: Themes.cream)),
                    ),
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
