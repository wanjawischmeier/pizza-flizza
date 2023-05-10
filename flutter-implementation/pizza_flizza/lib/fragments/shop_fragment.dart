import 'dart:math';
import 'package:cached_firestorage/lib.dart';
import 'package:flutter/material.dart';
import 'package:pizza_flizza/database.dart';
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
      child: _locked
          ? AspectRatio(
              aspectRatio: 0.75,
              child: Container(
                decoration: BoxDecoration(
                  color: Themes.grayMid,
                  borderRadius: BorderRadius.circular(35),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: RemotePicture(
                                    imagePath: '/shops/${Shop.shopId}/logo.png',
                                    mapKey: '${Shop.shopId}_logo',
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    Shop.shopName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('Große Burgstraße 55, 23552 Lübeck'),
                                const Text(
                                    'Heute geöffnet von 07:00 - 22:00 Uhr'),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text('4/10 Bestellungen erfüllt'),
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: LinearProgressIndicator(
                                      backgroundColor: Themes.grayLight,
                                      minHeight: 16,
                                      value: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SlideAction(
                      sliderRotate: false,
                      outerColor: Themes.grayLight,
                      animationDuration: const Duration(milliseconds: 100),
                      text: 'Slide to shop',
                      onSubmit: () {
                        setState(() {
                          _locked = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LinearProgressIndicator(
                    backgroundColor: Themes.grayMid,
                    minHeight: 16,
                    value: 0.4,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 0.7,
                      child: AppinioSlideSwiper(
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
                          int newCount = max(1,
                              min(_itemCount, (gradient * _itemCount).round()));
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
                  ),
                ),
              ],
            ),
    );
  }
}
