import 'package:flutter/material.dart';
import 'package:pizza_flizza/pages/intro_page/intro_page.dart';

class GroupSelectionSlide extends StatefulWidget {
  final OnContinue? onContinue;

  const GroupSelectionSlide({super.key, this.onContinue});

  @override
  State<GroupSelectionSlide> createState() => _GroupSelectionSlideState();
}

class _GroupSelectionSlideState extends State<GroupSelectionSlide> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.onContinue,
      child: Text('roups'),
    );
  }
}
