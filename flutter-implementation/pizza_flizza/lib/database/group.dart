import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:pizza_flizza/database/database.dart';

class Group {
  int groupId;
  String groupName;
  List<String> users;

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

  static List<String> parseUsers(List? rawUsers) {
    var users = <String>[];

    if (rawUsers != null) {
      for (String userId in rawUsers) {
        users.add(userId);
      }
    }

    return users;
  }

  static void initializeGroupUpdates() {
    onGroupUpdated(DatabaseEvent event) {
      String? key = event.snapshot.key;
      var group = event.snapshot.value as Map?;

      if (key != null && group != null) {
        int id = int.parse(key);

        _groups[id] = Group(
          id,
          group['name'],
          parseUsers(group['users']),
        );

        _groupsUpdatedController.add(_groups);
      }
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
  }

  static Future<void> cancelGroupUpdates() async {
    await _groupsDataAddedSubscription?.cancel();
    await _groupsDataChangedSubscription?.cancel();
    await _groupsDataRemovedSubscription?.cancel();

    _groupsDataAddedSubscription = null;
    _groupsDataChangedSubscription = null;
    _groupsDataRemovedSubscription = null;
  }

  static Future<int> createGroup(String groupName) async {
    int id = DateTime.now().millisecondsSinceEpoch;

    _groups[id] = Group(id, groupName, []);

    await Database.realtime.child('groups/$id').set({
      'name': groupName,
    });

    return id;
  }

  static Future<void> joinGroup(
      int groupId, String userId, String userName) async {
    var reference = Database.realtime.child('groups/$groupId/users');
    var snapshot = await reference.get();
    var users = snapshot.value as List?;

    if (users == null) {
      await reference.child('0').set(userId);
    } else if (!users.contains(userId)) {
      await reference.child(users.length.toString()).set(userId);
    }

    Database.realtime.child('users/$groupId/$userId/name').set(userName);
  }
}
