import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pizza_flizza/theme.dart';
import 'package:pizza_flizza/widgets/shop_card.dart';
import 'package:appinio_swiper/appinio_slide_swiper.dart';
import 'package:slide_to_act/slide_to_act.dart';

class ShopFragment extends StatefulWidget {
  const ShopFragment({super.key});

  @override
  State<ShopFragment> createState() => _ShopFragmentState();
}

class _ShopFragmentState extends State<ShopFragment> {
  int _itemCount = 0;
  double _gradient = 1;
  bool _locked = true;
  late int _count;

  @override
  Widget build(BuildContext context) {
    Map<String, int> orders = <String, int>{
      'Pizza': 4,
      'Borej': 10,
      'La baguette': 2,
    };

    return Container(
      padding: const EdgeInsets.all(24),
      child: AspectRatio(
        aspectRatio: 0.65,
        child: _locked
            ? SlideAction(
                sliderRotate: false,
                outerColor: Themes.cream,
                animationDuration: const Duration(milliseconds: 100),
                onSubmit: () {
                  setState(() {
                    _locked = false;
                  });
                },
              )
            : AppinioSlideSwiper(
                cardsCount: orders.length,
                threshold: 100,
                duration: const Duration(milliseconds: 150),
                absoluteAngle: true,
                cardsBuilder:
                    (BuildContext context, int index, bool foreground) {
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

                  return ShopCardWidget(
                      stop: foreground ? 1 - _gradient : 0,
                      name: itemName,
                      count: currentCount);
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
      ),
    );
  }
}
