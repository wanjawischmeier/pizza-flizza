import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:pizza_flizza/database/group.dart';
import 'package:pizza_flizza/other/theme.dart';

typedef OnGroupNameChanged = void Function(String groupName, int? groupId);

class GroupSelectionField extends StatefulWidget {
  final OnGroupNameChanged? onGroupNameChanged;
  final OnGroupNameChanged? onSelectionConfirmed;
  final String? error;
  final bool autofocus;
  final Color suggestionBackgroundColor;

  const GroupSelectionField({
    super.key,
    this.error,
    this.autofocus = false,
    this.suggestionBackgroundColor = Themes.grayMid,
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
          labelText: 'Group',
          helperText: _groupNameHint,
          errorText: widget.error,
          suffixIcon: _groupActionIcon ?? const SizedBox(height: 0),
          hintText: 'Enter the name of a group',
        ),
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
            _groupNameHint = 'A new group will be created';
          } else {
            _matchingGroups.clear();
            _groupId = exactlyMatching.firstOrNull?.groupId;
            _groupActionIcon = const Icon(Icons.add_reaction);
            _groupNameHint = 'You will be added to the group';
          }

          setState(() {});
          widget.onGroupNameChanged?.call(value, _groupId);
        },
        onSubmitted: (value) {
          if (value.isNotEmpty) {
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
              '${suggestion.users.length} member${suggestion.users.length == 1 ? '' : 's'}'),
        );
      },
      noItemsFoundBuilder: (context) => const SizedBox(),
      onSuggestionSelected: (suggestion) {
        _groupId = suggestion.groupId;

        setState(() {
          _matchingGroups.clear();
          _groupActionIcon = const Icon(Icons.add_reaction);
          _groupNameHint = 'You will be added to the group';
          _groupNameController.text = suggestion.groupName;
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
