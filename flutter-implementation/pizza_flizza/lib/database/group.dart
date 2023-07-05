import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pizza_flizza/database/database.dart';

import 'shop.dart';

class Group {
  int groupId;
  String groupName;
  Map<String, String> users;

  Group(
    this.groupId,
    this.groupName,
    this.users,
  );

  static StreamSubscription<DatabaseEvent>? _groupsDataAddedSubscription;
  static StreamSubscription<DatabaseEvent>? _groupsDataChangedSubscription;
  static StreamSubscription<DatabaseEvent>? _groupsDataRemovedSubscription;
  static final StreamController<Map<int, Group>> _groupsUpdatedController =
      StreamController.broadcast();
  static StreamSubscription<Map<int, Group>> subscribeToGroupsUpdated(
      void Function(Map<int, Group> groups) onUpdate) {
    onUpdate(_groups);
    return _groupsUpdatedController.stream.listen(onUpdate);
  }

  static final _groups = <int, Group>{};
  static Map<int, Group> get groups => _groups;

  static void _parseAndAddGroup(String? key, Map? group) {
    if (key == null || group == null) {
      return;
    }

    int id = int.parse(key);
    var rawUsers = group['users'] as Map?;
    var users = <String, String>{};

    if (rawUsers != null) {
      rawUsers.forEach((userId, userName) {
        if (userId != null) {
          users[userId] = userName;
        }
      });
    }

    _groups[id] = Group(
      id,
      group['name'],
      users,
    );

    _groupsUpdatedController.add(_groups);
  }

  static Future<void> initializeListeners() async {
    onGroupUpdated(DatabaseEvent event) {
      _parseAndAddGroup(
        event.snapshot.key,
        event.snapshot.value as Map?,
      );
    }

    onGroupRemoved(DatabaseEvent event) {
      String? key = event.snapshot.key;

      if (key != null) {
        _groups.remove(int.parse(key));
        _groupsUpdatedController.add(_groups);
      }
    }

    var reference = Database.realtime.child('groups');
    _groupsDataAddedSubscription =
        reference.onChildAdded.listen(onGroupUpdated);
    _groupsDataChangedSubscription =
        reference.onChildChanged.listen(onGroupUpdated);
    _groupsDataRemovedSubscription =
        reference.onChildRemoved.listen(onGroupRemoved);

    var snapshot = await reference.get();
    var groups = snapshot.value as Map?;
    groups?.forEach((key, group) {
      _parseAndAddGroup(key, group);
    });
  }

  static Future<void> cancelGroupListeners() async {
    await _groupsDataAddedSubscription?.cancel();
    await _groupsDataChangedSubscription?.cancel();
    await _groupsDataRemovedSubscription?.cancel();

    _groupsDataAddedSubscription = null;
    _groupsDataChangedSubscription = null;
    _groupsDataRemovedSubscription = null;
  }

  /// Initializes a group's entry in the local database and cloud.
  /// Can ONLY be called if an entry does not already exist.
  /// Returns the created group's id.
  static Future<Group> initializeGroupWithUser(
      String groupName, String userId, String userName) async {
    var group = Group(
      DateTime.now().millisecondsSinceEpoch,
      groupName,
      {userId: userName},
    );

    _groups[group.groupId] = group;
    await Database.realtime.child('groups/${group.groupId}').set({
      'name': groupName,
      'users': {userId: userName},
    });

    return group;
  }

  static Future<Group> joinGroup(
      String groupName, int? groupId, String userId, String userName) async {
    if (FirebaseAuth.instance.currentUser?.uid != userId) {
      // the user does not have the required database access
      throw Exception('database.not_signed_in'.tr());
    }

    Group? group;

    if (groupId == null) {
      // no existing group referenced, create and initialize group
      group = await initializeGroupWithUser(groupName, userId, userName);
      groupId = group.groupId;
    } else {
      // check wether group exists in database
      group = _groups[groupId];
      if (group == null) {
        // for some reason an id is passed that does not exist in the database
        // discard it and create a new one
        group = await initializeGroupWithUser(groupName, userId, userName);
        _groups[groupId] = group;
        groupId = group.groupId;
      } else {
        group.users[userId] = userName;

        // we don't have write access to the whole group
        // only write users entry
        await Database.realtime
            .child('groups/$groupId/users/$userId')
            .set(userName);
      }
    }

    return group;
  }

  static Future<Group> switchGroup(String newGroupName, int? newGroupId,
      String userId, String userName) async {
    Group? oldGroup = findUserGroup(userId);
    if (oldGroup == null) {
      return await joinGroup(newGroupName, newGroupId, userId, userName);
    }

    if (oldGroup.groupId == newGroupId) {
      return oldGroup;
    }

    var group = await joinGroup(newGroupName, newGroupId, userId, userName);

    var futures = <Future>[];
    if (oldGroup.users.length <= 1) {
      // the group is empty apart from the current user, remove it
      futures.add(
        Database.realtime.child('groups/${oldGroup.groupId}').remove(),
      );
    } else {
      // only remove the current user
      futures.add(
        Database.realtime
            .child('groups/${oldGroup.groupId}/users/$userId')
            .remove(),
      );
    }

    // delete all user data in old group
    // orders, fulfilled and history
    var future = Database.userReference?.remove();
    if (future != null) {
      futures.add(future);
    }

    // check whether other users have fulfilled for current user
    Shop.fulfilled.forEach((fulfillerId, fulfilledOrders) {
      fulfilledOrders.forEach((shopId, shopOrders) {
        shopOrders.forEach((fulfilledForId, order) {
          if (fulfilledForId == userId) {
            var future = Database.groupReference
                ?.child('$fulfillerId/fulfilled/$shopId/$fulfilledForId')
                .remove();

            if (future != null) {
              futures.add(future);
            }
          }
        });
      });
    });

    await Future.wait(futures);
    return group;
  }

  static Group? findUserGroup(String userId) {
    return _groups.values
        .where((group) => group.users.containsKey(userId))
        .firstOrNull;
  }
}
