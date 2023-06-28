import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:pizza_flizza/database/group.dart';
import 'package:pizza_flizza/other/theme.dart';

typedef OnGroupNameChanged = void Function(String groupName, int? groupId);

class GroupSelectionField extends StatefulWidget {
  final OnGroupNameChanged? onGroupNameChanged;
  final OnGroupNameChanged? onSelectionConfirmed;
  final int? groupId;
  final String? groupName, error;
  final bool enabled, autofocus, clearHintOnConfirm;
  final Color suggestionBackgroundColor;
  final Widget? suffix;

  const GroupSelectionField({
    super.key,
    this.groupId,
    this.groupName,
    this.error,
    this.enabled = true,
    this.autofocus = false,
    this.clearHintOnConfirm = false,
    this.suggestionBackgroundColor = Themes.grayMid,
    this.suffix,
    this.onGroupNameChanged,
    this.onSelectionConfirmed,
  });

  @override
  State<GroupSelectionField> createState() => GroupSelectionFieldState();
}

class GroupSelectionFieldState extends State<GroupSelectionField> {
  int? _groupId;
  String? _groupNameHint;
  final TextEditingController _groupNameController = TextEditingController();

  StreamSubscription<Map<int, Group>>? _groupsUpdatedSubscription;
  var _groups = <int, Group>{};
  var _matchingGroups = <Group>[];
  Icon? _groupActionIcon;

  @override
  void initState() {
    super.initState();

    _groupId = widget.groupId;
    _groupNameController.text = widget.groupName ?? '';

    _groupsUpdatedSubscription = Group.subscribeToGroupsUpdated((groups) {
      setState(() {
        _groups = groups;
      });
    });
  }

  @override
  void dispose() {
    _groupsUpdatedSubscription?.cancel();
    _groupsUpdatedSubscription = null;
    _groupNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField(
      textFieldConfiguration: TextFieldConfiguration(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          suffix: widget.suffix,
          labelText: 'login.fields.group.title'.tr(),
          helperText: _groupNameHint,
          errorText: widget.error,
          suffixIcon: (widget.suffix == null)
              ? _groupActionIcon ?? const SizedBox(height: 0)
              : null,
          hintText: 'login.fields.group.hint'.tr(),
        ),
        enabled: widget.enabled,
        controller: _groupNameController,
        focusNode: widget.autofocus ? (FocusNode()..requestFocus()) : null,
        onChanged: (value) {
          if (value.isEmpty) {
            setState(() {
              _matchingGroups.clear();
              _groupId = null;
              _groupActionIcon = null;
              _groupNameHint = null;
            });

            widget.onGroupNameChanged?.call(value, _groupId);
            return;
          }

          _matchingGroups = _groups.values
              .where(
                (group) =>
                    group.groupName.toLowerCase().contains(value.toLowerCase()),
              )
              .toList();

          var exactlyMatching =
              _matchingGroups.where((group) => group.groupName == value);

          if (exactlyMatching.isEmpty) {
            _groupId = null;
            _groupActionIcon = const Icon(Icons.add);
            _groupNameHint = 'login.fields.group.hint_create'.tr();
          } else {
            _groupId = exactlyMatching.firstOrNull?.groupId;
            _matchingGroups.clear();
            _groupActionIcon = const Icon(Icons.add_reaction);
            _groupNameHint = 'login.fields.group.hint_add'.tr();
          }

          setState(() {});
          widget.onGroupNameChanged?.call(value, _groupId);
        },
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            if (widget.clearHintOnConfirm) {
              setState(() {
                _groupActionIcon = null;
                _groupNameHint = null;
              });
            }

            widget.onSelectionConfirmed?.call(value, _groupId);
          }
        },
      ),
      suggestionsCallback: (pattern) => _matchingGroups,
      itemBuilder: (context, suggestion) {
        return ListTile(
          tileColor: widget.suggestionBackgroundColor,
          leading: const Icon(Icons.group),
          title: Text(suggestion.groupName),
          subtitle: Text(
            'login.fields.group.subtitle_${suggestion.users.length == 1 ? 'singular' : 'plural'}',
          ).tr(args: [suggestion.users.length.toString()]),
        );
      },
      noItemsFoundBuilder: (context) => const SizedBox(),
      onSuggestionSelected: (suggestion) {
        _groupId = suggestion.groupId;

        setState(() {
          _matchingGroups.clear();
          _groupNameController.text = suggestion.groupName;

          if (widget.clearHintOnConfirm) {
            _groupActionIcon = null;
            _groupNameHint = null;
          } else {
            _groupActionIcon = const Icon(Icons.add_reaction);
            _groupNameHint = 'login.fields.group.hint_add'.tr();
          }
        });

        widget.onSelectionConfirmed?.call(suggestion.groupName, _groupId);
      },
    );
  }

  void reset() {
    setState(() {
      _groupId = null;
      _groupNameHint = null;
      _groupActionIcon = null;
      _groupNameController.text = '';
      _matchingGroups.clear();
    });
  }
}
