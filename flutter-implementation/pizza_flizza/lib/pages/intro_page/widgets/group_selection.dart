import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pizza_flizza/other/theme.dart';
import 'package:pizza_flizza/widgets/group_selection_field.dart';

typedef OnGroupSelected = void Function(String groupName, int? groupId);

class GroupSelectionSlide extends StatefulWidget {
  final OnGroupSelected? onGroupSelected;

  const GroupSelectionSlide({super.key, this.onGroupSelected});

  @override
  State<GroupSelectionSlide> createState() => _GroupSelectionSlideState();
}

class _GroupSelectionSlideState extends State<GroupSelectionSlide> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 150,
          padding: const EdgeInsets.only(bottom: 16),
          child: ClipOval(
            child: Container(
              padding: const EdgeInsets.all(30),
              color: Themes.grayMid,
              child: const FittedBox(
                child: Icon(
                  Icons.group_add_outlined,
                  color: Themes.cream,
                ),
              ),
            ),
          ),
        ),
        Text(
          'intro.group_selection.title'.tr(),
          style: const TextStyle(fontSize: 22),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 32),
          child: Text(
            'intro.group_selection.subtitle'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: GroupSelectionField(
            autofocus: true,
            onSelectionConfirmed: (groupName, groupId) async {
              Future.delayed(
                const Duration(milliseconds: 250),
                () => widget.onGroupSelected?.call(groupName, groupId),
              );
            },
          ),
        ),
        const Spacer(),
        const SizedBox(height: 60),
      ],
    );
  }
}
