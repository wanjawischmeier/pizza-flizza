import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_firestorage/lib.dart';
import 'package:pizza_flizza/database/database.dart';

import 'package:slide_to_act/slide_to_act.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';

import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:appinio_swiper/appinio_slide_swiper.dart';

import 'package:pizza_flizza/database/item.dart';
import 'package:pizza_flizza/database/order.dart';
import 'package:pizza_flizza/database/shop.dart';
import 'package:pizza_flizza/other/theme.dart';
import 'package:pizza_flizza/pages/home_page/shop_fragment/widgets/shop_card.dart';

enum ShopState { locked, unlocked, noOrders }

class ShopFragment extends StatefulWidget {
  const ShopFragment({super.key});

  @override
  State<ShopFragment> createState() => _ShopFragmentState();
}

class _ShopFragmentState extends State<ShopFragment>
    with TickerProviderStateMixin {
  OrderItem? _foregroundItem, _backgroundItem;
  double _gradient = 1;
  double _swipedCount = 0;
  ShopState _state = ShopState.locked;
  late int _count;
  late AnimationController _controller;
  static const Duration _animationDurationIn = Duration(milliseconds: 300);
  static const Duration _animationDurationOut = Duration(milliseconds: 150);
  late final Animation<Offset> _slideAnimation = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0, -2),
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInCirc,
  ));
  late final Animation<double> _opacityAnimation = ReverseAnimation(
    CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCirc,
    ),
  );

  late StreamSubscription<String> _shopChangedSubscription;
  late StreamSubscription<OrderMap> _ordersSubscription2;
  final _ordersShop = <int, OrderItem>{};
  final _fulfilled = <String>[];

  void filterOrders(OrderMap orders, {bool lock = false}) {
    _ordersShop.clear();

    // loop through orders for all users
    orders.forEach((userId, userOrders) {
      // select currentShop
      userOrders[Shop.currentShopId]?.items.forEach((itemId, item) {
        if (!_fulfilled.contains(itemId)) {
          // use hash to account for possible duplicate itemId's across shops
          _ordersShop[item.hashCode] = OrderItem.copy(item);
        }
      });
    });

    if (_foregroundItem == null && _ordersShop.isNotEmpty) {
      _foregroundItem = _ordersShop.values.first;
    }

    if (_backgroundItem == null && _ordersShop.length > 1) {
      _backgroundItem = _ordersShop.values.elementAt(1);
    }

    setState(() {
      _count = _foregroundItem?.count ?? 0;

      if (_ordersShop.isEmpty) {
        _state = ShopState.noOrders;
        _controller.forward();
      } else if (lock) {
        _state = ShopState.locked;
        _controller.forward();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDurationIn,
      reverseDuration: _animationDurationOut,
      value: 1,
    );

    _ordersSubscription2 = Shop.subscribeToOrdersUpdated((orders) {
      filterOrders(orders);
    });

    _shopChangedSubscription = Shop.subscribeToShopChanged((shopId) {
      _fulfilled.clear();
      filterOrders(Shop.orders, lock: true);
    });
  }

  @override
  void dispose() {
    _shopChangedSubscription.cancel();
    _ordersSubscription2.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SlideTransition(
                position: _slideAnimation,
                child: FAProgressBar(
                  backgroundColor: Themes.grayMid,
                  progressColor: Themes.cream,
                  borderRadius: BorderRadius.circular(99),
                  maxValue: _swipedCount + _ordersShop.length,
                  currentValue: _swipedCount,
                ),
              ),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 0.7,
                    child: FadeTransition(
                      opacity: _opacityAnimation,
                      child: AppinioSlideSwiper(
                        threshold: 100,
                        duration: const Duration(milliseconds: 150),
                        absoluteAngle: true,
                        isDisabled: _foregroundItem == null,
                        foregroundCardBuilder: (context) {
                          var item = _foregroundItem;
                          if (item == null) {
                            return null;
                          }

                          return ShopCardWidget(
                            stop: 1 - _gradient,
                            name: item.itemName,
                            count: _count,
                          );
                        },
                        backgroundCardBuilder: (context) {
                          var item = _backgroundItem;
                          if (item == null) {
                            return null;
                          }

                          return ShopCardWidget(
                            stop: 0,
                            name: item.itemName,
                            count: item.count,
                          );
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
                            Shop.fulfillItem(item, _count);
                          }

                          _gradient = 1;
                          _count = _backgroundItem?.count ?? 0;

                          var firstOrderEntry = _ordersShop.entries.first;
                          int orderHash = firstOrderEntry.key;
                          var orderItem = firstOrderEntry.value;
                          _ordersShop.remove(orderHash);
                          _fulfilled.add(orderItem.itemId);

                          _foregroundItem = _backgroundItem;
                          if (_ordersShop.length > 1) {
                            _backgroundItem = _ordersShop.values.elementAt(1);
                          } else {
                            _backgroundItem = null;
                          }

                          if (_ordersShop.isEmpty) {
                            if (_fulfilled.isEmpty) {
                              _state = ShopState.noOrders;
                              _controller.forward();
                            } else {
                              _state = ShopState.locked;
                              _fulfilled.clear();
                              // some unfulfilled: restore original orders
                              filterOrders(Shop.orders, lock: true);
                            }

                            return false;
                          } else {
                            setState(() {
                              _swipedCount++;
                            });
                            return true;
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Center(
            child: FractionalTranslation(
              translation: const Offset(0, 0.1),
              child: AspectRatio(
                aspectRatio: 0.8,
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _controller,
                    curve: const ElasticOutCurve(1),
                    reverseCurve: Curves.easeOut,
                  ),
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
                                          borderRadius:
                                              BorderRadius.circular(32),
                                          border: Border.all(
                                              color: Themes.grayDark,
                                              width: 16),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: RemotePicture(
                                            imagePath:
                                                '/images/${Database.imageResolution}/shops/${Shop.currentShopId}/logo_large.png',
                                            mapKey:
                                                '${Shop.currentShopId}_logo_large_${Database.imageResolution}',
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
                                      // const Text('msg').tr(),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  /*
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(bottom: 8),
                                            child:
                                                Text('Erfüllte Bestellungen:'),
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
                                  */
                                  child: Text(
                                    'shop information\ncoming soon :)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SlideAction(
                          sliderRotate: false,
                          enabled: _state == ShopState.locked,
                          textColor: Colors.white,
                          innerColor: _state == ShopState.noOrders
                              ? Themes.grayLight
                              : Colors.white,
                          outerColor: Themes.grayLight,
                          animationDuration: const Duration(milliseconds: 100),
                          text: _state == ShopState.noOrders
                              ? 'No open orders'
                              : 'Slide to shop',
                          onSubmit: () {
                            return _controller.reverse();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
