import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pizza_flizza/widgets/card_widget.dart';
import 'package:appinio_swiper/appinio_slide_swiper.dart';

class ShopFragment extends StatefulWidget {
  const ShopFragment({super.key});

  @override
  State<ShopFragment> createState() => _ShopFragmentState();
}

class _ShopFragmentState extends State<ShopFragment> {
  int _itemCount = 0;
  double _gradient = 1;
  late int _count;

  @override
  Widget build(BuildContext context) {
    Map<String, int> orders = <String, int>{
      'Pizza': 4,
      'Borej': 10,
      'La baguette': 2,
    };

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: AppinioSlideSwiper(
        cardsCount: orders.length,
        threshold: 100,
        duration: const Duration(milliseconds: 150),
        absoluteAngle: true,
        cardsBuilder: (BuildContext context, int index, bool foreground) {
          var entry = orders.entries.elementAt(index);
          String itemName = entry.key;
          int currentCount = entry.value;
          if (foreground) {
            if (_itemCount == currentCount) {
              currentCount = _count;
            } else {
              _itemCount = currentCount;
              _count = currentCount;
              _gradient = 1;
            }
          }

          return CardWidget(
              stop: foreground ? 1 - _gradient : 0,
              name: itemName,
              currentCount: currentCount);
        },
        onSlide: (index, gradient) {
          // snap to range
          int newCount =
              max(1, min(_itemCount, (gradient * _itemCount).round()));
          _gradient = newCount / _itemCount;

          if (newCount == _count) {
            return false;
          } else {
            setState(() {
              _count = newCount;
            });
            return true;
          }
        },
      ),
    );
  }
}
