import 'dart:async';

import 'package:flutter/material.dart';

import 'package:pizza_flizza/database/shop.dart';
import 'package:pizza_flizza/other/helper.dart';
import 'package:pizza_flizza/other/theme.dart';

class OrderBottomBar extends StatefulWidget {
  const OrderBottomBar({super.key});

  @override
  State<OrderBottomBar> createState() => _OrderBottomBarState();
}

class _OrderBottomBarState extends State<OrderBottomBar>
    with TickerProviderStateMixin {
  double _currentTotal = 0;
  bool _visible = false;
  late StreamSubscription<String> _shopChangedSubscription;
  late StreamSubscription<double> _currentTotalSubscription;
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  @override
  void initState() {
    super.initState();
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() {
          _visible = false;
        });
      }
    });
    _shopChangedSubscription = Shop.subscribeToShopChanged((shopId) {
      setState(() {
        // a bit hacky but oh well
        _currentTotal = -1;
        _visible = false;
      });
    });
    _currentTotalSubscription = Shop.subscribeToCurrentTotal((total) {
      if (_currentTotal == -1) {
        _currentTotal = 0;
        return;
      }

      setState(() {
        _currentTotal = total;
      });

      if (_currentTotal == 0) {
        _animationController.reverse();
      } else {
        _visible = true;
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _shopChangedSubscription.cancel();
    _currentTotalSubscription.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1), // Start position (offscreen)
        end: Offset.zero, // End position (onscreen)
      ).animate(_animationController),
      child: Visibility(
        visible: _visible,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Themes.grayDark,
            borderRadius:
                BorderRadiusDirectional.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: Themes.grayMid,
                spreadRadius: 2,
                blurRadius: 4,
              )
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      Shop.currentOrderString,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Themes.grayMid,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Center(
                      child: Text(
                        Helper.formatPrice(_currentTotal),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: Shop.pushCurrentOrder,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Order',
                      style: TextStyle(fontSize: 18),
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
