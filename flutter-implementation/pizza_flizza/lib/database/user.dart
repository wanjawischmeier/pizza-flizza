import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pizza_flizza/database/group.dart';

import 'database.dart';

// shopId, itemId -> count
typedef UserStats = Map<String, Map<String, int>>;

class UserData {
  String userId, userName;
  String? userEmail, providerId;
  Group group;

  DatabaseReference get databaseReference =>
      Database.realtime.child('users/${group.groupId}/$userId');

  UserData(
    this.userId,
    this.userName,
    this.userEmail,
    this.group,
    this.providerId,
  );

  UserData.fromFirebaseUser(User firebaseUser, this.userName, this.group)
      : userId = firebaseUser.uid,
        userEmail = firebaseUser.email,
        providerId = firebaseUser.providerData.firstOrNull?.displayName;

  static Future<Map<String, UserData>> loadUserStats(UserData user) async {
    var users = <String, UserData>{};

    var firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return users;
    }

    var snapshot = await Database.realtime
        .child('users/${user.group.groupId}/${user.userId}/stats')
        .get();
    var data = snapshot.value as Map?;
    if (data == null) {
      return users;
    }

    // get stats
    var rawStats = (data['stats'] as Map?) ?? {};
    var stats = <String, Map<String, int>>{};
    rawStats.forEach((shopId, shopStats) {
      stats[shopId] = {};

      (shopStats as Map?)?.forEach((itemId, count) {
        stats[shopId]![itemId] = count;
      });
    });

    return users;
  }

  static Future<Map<String, String>> loadUsersInGroup(Group group,
      [Map? rawNames]) async {
    var users = <String, String>{};

    if (rawNames == null) {
      var snapshot =
          await Database.realtime.child('groups/${group.groupId}/users').get();
      rawNames = snapshot.value as Map?;
      if (rawNames == null) {
        return users;
      }
    }

    rawNames.forEach((userId, userName) {
      // create entry
      users[userId] = userName;
    });

    return users;
  }
}
