import 'package:flutter/material.dart';
import 'package:pizza_flizza/other/theme.dart';
import 'package:pizza_flizza/widgets/group_selection_field.dart';

class GroupSelectionDialog extends StatefulWidget {
  final OnGroupNameChanged? onSelectionConfirmed;

  const GroupSelectionDialog({
    super.key,
    this.onSelectionConfirmed,
  });

  @override
  State<GroupSelectionDialog> createState() => _GroupSelectionDialogState();
}

class _GroupSelectionDialogState extends State<GroupSelectionDialog> {
  int? _groupId;
  String _groupName = '';
  bool _enabled = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Themes.grayMid,
      title: const Text('Select a group'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GroupSelectionField(
            autofocus: true,
            suggestionBackgroundColor: Themes.grayLight,
            onGroupNameChanged: (groupName, groupId) {
              if (_enabled && groupName.isEmpty) {
                setState(() {
                  _enabled = false;
                });
              }

              if (!_enabled && groupName.isNotEmpty) {
                setState(() {
                  _enabled = true;
                });
              }
            },
            onSelectionConfirmed: widget.onSelectionConfirmed,
          ),
          Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  height: _enabled ? 70 : 0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.fastOutSlowIn,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
