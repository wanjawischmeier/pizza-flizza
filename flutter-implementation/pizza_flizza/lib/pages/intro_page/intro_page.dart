import 'package:flutter/material.dart';
import 'package:pizza_flizza/other/theme.dart';
import 'package:pizza_flizza/pages/intro_page/page_physics.dart';

import 'widgets/group_selection.dart';
import 'widgets/privacy_policy.dart';

typedef OnIntroCanceled = void Function();

class IntroPage extends StatefulWidget {
  final OnIntroCanceled? onIntroCanceled;
  final OnGroupSelected? onIntroComplete;

  const IntroPage({
    super.key,
    this.onIntroCanceled,
    this.onIntroComplete,
  });

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _pageController = PageController();
  double _currentPage = 0;
  String? _groupName;
  int? _groupId;

  late final List<Widget> _slides;

  @override
  void initState() {
    super.initState();

    _slides = [
      GroupSelectionSlide(
        onGroupSelected: (groupName, groupId) {
          _groupName = groupName;
          _groupId = groupId;

          _goToPage(1);
        },
      ),
      PrivacyPolicySlide(
        onContinue: () {
          if (_groupName == null) {
            _goToPage(0);
          } else {
            widget.onIntroComplete?.call(_groupName!, _groupId);
          }
        },
      ),
    ];

    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            WillPopScope(
              onWillPop: () {
                if (_currentPage.round() == 0) {
                  widget.onIntroCanceled?.call();
                } else {
                  _goToPage(_currentPage.round() - 1);
                }

                return Future(() => false);
              },
              child: PageView(
                controller: _pageController,
                physics: CustomLockScrollPhysics(lockRight: true),
                children: _slides,
              ),
            ),
            AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                double value =
                    1.0 - (_currentPage - (_pageController.page ?? 0)).abs();
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildPageIndicator(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPageIndicator() {
    List<Widget> indicators = [];
    for (int i = 0; i < _slides.length; i++) {
      indicators.add(
        Container(
          width: 10.0,
          height: 10.0,
          margin: const EdgeInsets.symmetric(horizontal: 6.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage.round() == i ? Themes.cream : Themes.grayLight,
          ),
        ),
      );
    }
    return indicators;
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }
}
