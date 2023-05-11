import 'dart:async';
import 'dart:math';
import 'package:appinio_swiper/appinio_swiper.dart';
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
  late OrderItem _item;
  int _itemCount = 0;
  double _gradient = 1;
  bool _locked = true;
  late int _count;

  late StreamSubscription<String> _shopChangedSubscription;
  late StreamSubscription<List<OrderItem>> _openOrdersSubscription;
  var _orders = <OrderItem>[];
  Iterable<OrderItem> get _shopOrders {
    return _orders.where((item) => item.shopId == Shop.shopId);
  }

  @override
  void initState() {
    super.initState();
    _shopChangedSubscription = Shop.subscribeToShopChanged((shopId) {
      setState(() {
        _locked = true;
      });
    });
    _openOrdersSubscription = Shop.subscribeToOrderUpdated((orders) {
      setState(() {
        _orders = orders;
      });
    });
    _orders = Shop.flattenedOpenOrders;
    _item = _orders.first;
  }

  @override
  void dispose() {
    super.dispose();
    _shopChangedSubscription.cancel();
    _openOrdersSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: _locked
          ? FractionalTranslation(
              translation: const Offset(0, 0.1),
              child: AspectRatio(
                aspectRatio: 0.8,
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
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              FractionalTranslation(
                                translation: const Offset(0, -0.35),
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Themes.grayDark,
                                        borderRadius: BorderRadius.circular(32),
                                        border: Border.all(
                                            color: Themes.grayDark, width: 16),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: RemotePicture(
                                          imagePath:
                                              '/shops/${Shop.shopId}/logo.png',
                                          mapKey: '${Shop.shopId}_logo',
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8,
                                        bottom: 16,
                                      ),
                                      child: Text(
                                        Shop.shopName,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                        'Große Burgstraße 55, 23552 Lübeck'),
                                    const Text(
                                        'Heute geöffnet von 07:00 - 22:00 Uhr'),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child:
                                              Text('4/10 Bestellungen erfüllt'),
                                        ),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: LinearProgressIndicator(
                                            backgroundColor: Themes.grayLight,
                                            minHeight: 16,
                                            value: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                        cardsCount: _shopOrders.length,
                        threshold: 100,
                        duration: const Duration(milliseconds: 150),
                        absoluteAngle: true,
                        cardsBuilder:
                            (BuildContext context, int index, bool foreground) {
                          var item = _shopOrders.elementAt(index);

                          if (foreground) {
                            if (_itemCount == item.count) {
                              _item = item;
                              item.count = _count;
                            } else {
                              _itemCount = item.count;
                              _count = item.count;
                              _gradient = 1;
                            }
                          }

                          return ShopCardWidget(
                              stop: foreground ? 1 - _gradient : 0,
                              name: item.name,
                              count: item.count);
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
                        onSwipe: (count, direction) {
                          if (direction == AppinioSwiperDirection.right) {
                            _orders.remove(_item);
                            Shop.removeItem(_item);
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
