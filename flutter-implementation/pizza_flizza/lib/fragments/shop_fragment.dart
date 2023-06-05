import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_firestorage/lib.dart';

import 'package:slide_to_act/slide_to_act.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';

import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:appinio_swiper/appinio_slide_swiper.dart';

import 'package:pizza_flizza/database/item.dart';
import 'package:pizza_flizza/database/order.dart';
import 'package:pizza_flizza/database/shop.dart';
import 'package:pizza_flizza/theme.dart';
import 'package:pizza_flizza/widgets/shop_card.dart';

class ShopFragment extends StatefulWidget {
  const ShopFragment({super.key});

  @override
  State<ShopFragment> createState() => _ShopFragmentState();
}

class _ShopFragmentState extends State<ShopFragment> {
  OrderItem2? _foregroundItem, _backgroundItem;
  double _gradient = 1;
  bool _locked = true;
  double _swipedCount = 0;
  // late double _cardCount;
  late int _count;

  late StreamSubscription<String> _shopChangedSubscription;
  late StreamSubscription<OrderMap> _ordersSubscription2;
  final _ordersShop = <int, OrderItem2>{};

  @override
  void initState() {
    super.initState();

    _ordersSubscription2 = Shop.subscribeToOrdersUpdated2((orders) {
      _ordersShop.clear();

      // loop through orders for all users
      orders.forEach((userId, userOrders) {
        // select currentShop
        userOrders[Shop.currentShopId]?.items.forEach((itemId, item) {
          // use hash to account for possible duplicate itemId's across shops
          _ordersShop[item.hashCode] = OrderItem2.copy(item);
        });
      });

      if (_foregroundItem == null && _ordersShop.isNotEmpty) {
        _foregroundItem = _ordersShop.values.first;
      }

      if (_backgroundItem == null && _ordersShop.length > 1) {
        _foregroundItem = _ordersShop.values.elementAt(1);
      }

      setState(() {
        _count = _foregroundItem?.count ?? 0;
      });
    });

    _shopChangedSubscription = Shop.subscribeToShopChanged((shopId) {
      setState(() {
        _locked = true;
        _ordersShop.clear();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _shopChangedSubscription.cancel();
    _ordersSubscription2.cancel();
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
                                              '/shops/${Shop.currentShopId}/logo.png',
                                          mapKey: '${Shop.currentShopId}_logo',
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8,
                                        bottom: 16,
                                      ),
                                      child: Text(
                                        Shop.currentShopName,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    /*
                                    const Text(
                                        'Große Burgstraße 55, 23552 Lübeck'),
                                    const Text(
                                        'Heute geöffnet von 07:00 - 22:00 Uhr'),
                                    */
                                    const Text('More information coming soon'),
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
                                        const Padding(
                                          padding: EdgeInsets.only(bottom: 8),
                                          child: Text('Erfüllte Bestellungen:'),
                                        ),
                                        FAProgressBar(
                                          backgroundColor: Themes.grayLight,
                                          progressColor: Themes.cream,
                                          borderRadius:
                                              BorderRadius.circular(99),
                                          maxValue: 10,
                                          currentValue: 4,
                                          displayText: ' / 10',
                                          displayTextStyle: const TextStyle(
                                            fontWeight: FontWeight.bold,
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
                FAProgressBar(
                  backgroundColor: Themes.grayMid,
                  progressColor: Themes.cream,
                  borderRadius: BorderRadius.circular(99),
                  maxValue: _swipedCount + _ordersShop.length,
                  currentValue: _swipedCount,
                ),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 0.7,
                      child: AppinioSlideSwiper(
                        threshold: 100,
                        duration: const Duration(milliseconds: 150),
                        absoluteAngle: true,
                        isDisabled: _foregroundItem == null,
                        foregroundCardBuilder: (context) {
                          var item = _foregroundItem;
                          if (item == null) {
                            return Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Themes.grayMid,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: const Text(
                                  'No Cards',
                                  style: TextStyle(fontSize: 24),
                                ),
                              ),
                            );
                          } else {
                            return ShopCardWidget(
                              stop: 1 - _gradient,
                              name: item.itemName,
                              count: _count,
                            );
                          }
                        },
                        backgroundCardBuilder: (context) {
                          var item = _backgroundItem;
                          if (item == null) {
                            return null;
                          } else {
                            return ShopCardWidget(
                              stop: 0,
                              name: item.itemName,
                              count: item.count,
                            );
                          }
                        },
                        // only slide if the count is higher than 1
                        onStartSlide: () => (_foregroundItem?.count ?? 0) > 1,
                        onSlide: (gradient) {
                          // snap to range
                          int count = _foregroundItem?.count ?? 0;
                          int newCount =
                              max(1, min(count, (gradient * count).round()));
                          _gradient = newCount / count;

                          if (newCount == _count) {
                            return false;
                          } else {
                            setState(() {
                              _count = newCount;
                            });
                            return true;
                          }
                        },
                        onSwipe: (direction) {
                          var item = _foregroundItem;
                          if (item != null &&
                              direction == AppinioSwiperDirection.right) {
                            // ShopItem.getById(_fulfilled, item.id);
                            // _fulfilled[item.id] = _count;
                            Shop.fulfillItem(item, _count);
                          }

                          _gradient = 1;
                          _count = _backgroundItem?.count ?? 0;
                          _ordersShop.remove(_ordersShop.entries.first.key);

                          _foregroundItem = _backgroundItem;
                          if (_ordersShop.length > 1) {
                            _backgroundItem = _ordersShop.values.elementAt(1);
                          } else {
                            _backgroundItem = null;
                          }

                          setState(() {
                            _swipedCount++;
                          });
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
