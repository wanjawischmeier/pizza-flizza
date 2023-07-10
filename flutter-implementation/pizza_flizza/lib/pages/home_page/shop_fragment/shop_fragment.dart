import 'dart:async';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cached_firestorage/lib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/orders/order_manager.dart';
import 'package:pizza_flizza/database/orders/orders.dart';

import 'package:slide_to_act/slide_to_act.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';

import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:appinio_swiper/appinio_slide_swiper.dart';

import 'package:pizza_flizza/database/item.dart';
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
  int _count = 0;
  double _gradient = 1;
  ShopState _state = ShopState.locked;

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
  late StreamSubscription<OrderMap> _ordersSubscription;
  final _ordersShop = <OrderItem>[];
  final _used = <String>[];

  List<OrderItem>? _foregroundItems,
      _backgroundItems,
      _previousItems,
      _replacementItems;

  List<OrderItem>? _gatherNextItems() {
    if (_ordersShop.isEmpty) {
      return null;
    }

    OrderItem? first;
    for (var item in _ordersShop) {
      if (!_used.contains(item.itemId)) {
        first = item;
        break;
      }
    }

    if (first == null) {
      return null;
    }

    _used.add(first.itemId);
    var items = <OrderItem>[];

    for (var item in _ordersShop) {
      if (item.identityMatches(first)) {
        items.add(item);
      }
    }

    return items;
  }

  void _fulfillForegroundItems(bool isReplacement) {
    var items = _foregroundItems;
    if (items == null || items.isEmpty) {
      return;
    }

    if (items.totalItemCount <= _count) {
      // every order can be fulfilled
      _replacementItems = null;

      for (var item in items) {
        OrderManager.fulfillItem(item, item.count);
      }

      return;
    } else {
      // Distribute items fairly
      int remainingItems = _count;
      _replacementItems = [];
      _replacementItems!.clear();

      for (var item in items) {
        double distributionRatio = item.count / items.totalItemCount;
        int distributedQuantity = (distributionRatio * _count).round();

        if (distributedQuantity > item.count) {
          distributedQuantity = item.count;
        }

        if (distributedQuantity > remainingItems) {
          distributedQuantity = remainingItems;
        }

        if (distributedQuantity == 0) {
          break;
        }

        remainingItems -= distributedQuantity;
        OrderManager.fulfillItem(item, distributedQuantity);

        // don't futher replace replacements
        if (isReplacement) {
          continue;
        }

        // find replacement item
        var replacement = item.replacement;
        if (replacement == null) {
          continue;
        }

        _replacementItems!.add(replacement);
      }

      if (remainingItems > 0) {
        Fluttertoast.showToast(
          msg: 'Item distribution failed: $remainingItems items remaining.',
        );
      }
      /*
      // push in replacement if available
      if (_replacementItems.isNotEmpty) {
        if (_backgroundItems != null) {
          _ordersShop.addAll(_backgroundItems!);
        }

        _backgroundItems = _replacementItems;
      }
      */
    }
  }

  void filterOrders(OrderMap orders, {bool lock = false}) {
    _ordersShop.clear();

    // loop through orders for all users
    orders.forEach((userId, userOrders) {
      // select currentShop
      userOrders[Shop.currentShopId]?.items.forEach((itemId, item) {
        _ordersShop.add(OrderItem.from(item));
      });
    });

    // only assign new items if previously null
    _foregroundItems ??= _gatherNextItems();
    _backgroundItems ??= _gatherNextItems();

    // _previousItems = List.from(_foregroundItems!);

    setState(() {
      var oldState = _state;
      var foregroundCount = _foregroundItems?.totalItemCount ?? 0;

      if (_foregroundItems == null && _replacementItems == null) {
        _state = ShopState.noOrders;
      } else if (lock) {
        _state = ShopState.locked;
      }

      var foregroundItem = _foregroundItems?.firstOrNull;
      if (_count != _previousItems?.totalItemCount &&
          foregroundItem.identityMatches(_previousItems?.firstOrNull)) {
        _count = min(_count, foregroundCount);
        _gradient = _count / foregroundCount;
      } else {
        _count = foregroundCount;
      }

      // animate if state changed
      if (_state != oldState) {
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

    _ordersSubscription = Orders.subscribeToOrdersUpdated((orders) {
      filterOrders(orders);
    });

    _shopChangedSubscription = Shop.subscribeToShopChanged((shopId) {
      filterOrders(Orders.orders, lock: true);
    });
  }

  @override
  void dispose() {
    _shopChangedSubscription.cancel();
    _ordersSubscription.cancel();
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
                  maxValue: _used.length +
                      _ordersShop.length +
                      (_foregroundItems == null ? 0 : 1) +
                      (_backgroundItems == null ? 0 : 1),
                  currentValue: _used.length.toDouble(),
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
                        isDisabled: _foregroundItems == null &&
                            _replacementItems == null,
                        foregroundCardBuilder: (context) {
                          var replacement = _replacementItems?.firstOrNull;
                          if (replacement != null) {
                            // previous item has replacements
                            return ShopCardWidget(
                              stop: 1 - _gradient,
                              name: replacement.itemName,
                              count: replacement.count,
                            );
                          }

                          var item = _foregroundItems?.firstOrNull;
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
                          var replacement =
                              _replacementItems?.elementAtOrNull(1);
                          if (replacement != null) {
                            // previous item has replacements
                            return ShopCardWidget(
                              stop: 1 - _gradient,
                              name: replacement.itemName,
                              count: replacement.count,
                            );
                          }

                          var item = _backgroundItems?.firstOrNull;
                          if (item == null) {
                            return null;
                          }

                          return ShopCardWidget(
                            stop: 0,
                            name: item.itemName,
                            count: _backgroundItems?.totalItemCount ?? 0,
                          );
                        },
                        // only slide if the count is higher than 1
                        onStartSlide: () =>
                            (_foregroundItems?.totalItemCount ?? 0) > 1,
                        onSlide: (gradient) {
                          // snap to range
                          int count = _foregroundItems?.totalItemCount ?? 0;
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
                          var item = _replacementItems?.firstOrNull;
                          bool isReplacement = item != null;
                          item ??= _foregroundItems?.firstOrNull;

                          if (direction == AppinioSwiperDirection.right) {
                            _fulfillForegroundItems(isReplacement);
                          }

                          if (isReplacement && item != null) {
                            _replacementItems?.remove(item);

                            if (_replacementItems?.isEmpty ?? false) {
                              _replacementItems = null;
                            }
                          }

                          if (_backgroundItems == null &&
                              _replacementItems == null) {
                            setState(() {
                              _previousItems = null;
                              _state = ShopState.locked;

                              // wait for animation to finish
                              _controller.forward().then((value) {
                                setState(() {
                                  _used.clear();
                                  _foregroundItems = _gatherNextItems();
                                  _backgroundItems = _gatherNextItems();
                                  _gradient = 1;
                                  _count =
                                      _foregroundItems?.totalItemCount ?? 0;
                                });
                              });
                            });
                            return false;
                          }

                          if (_foregroundItems == null) {
                            _previousItems = null;
                          } else {
                            _previousItems = List.from(_foregroundItems!);
                          }
                          if (_backgroundItems == null) {
                            _foregroundItems = null;
                          } else {
                            _foregroundItems = List.from(_backgroundItems!);
                          }
                          _backgroundItems = _gatherNextItems();

                          _gradient = 1;
                          _count = _foregroundItems?.totalItemCount ?? 0;

                          return true;
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
                                        width: 150,
                                        height: 150,
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
                                            loadingIndicator: const Padding(
                                              padding: EdgeInsets.all(32),
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
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
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          innerColor: _state == ShopState.noOrders
                              ? Themes.grayLight
                              : Colors.white,
                          outerColor: Themes.grayLight,
                          animationDuration: const Duration(milliseconds: 100),
                          text: _state == ShopState.noOrders
                              ? 'shop.no_open_orders'.tr()
                              : 'shop.slide_to_shop'.tr(),
                          onSubmit: () {
                            _state = ShopState.unlocked;
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
