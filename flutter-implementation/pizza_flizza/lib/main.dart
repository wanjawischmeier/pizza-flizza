import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';

import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/group.dart';
import 'package:pizza_flizza/database/shop.dart';
import 'package:pizza_flizza/other/firebase_options.dart';
import 'package:pizza_flizza/pages/home_page/home_page.dart';
import 'package:pizza_flizza/pages/intro_page/intro_page.dart';
import 'package:pizza_flizza/pages/login_page/login_page.dart';
import 'package:pizza_flizza/other/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  bool validUser = false;

  await Group.initializeGroupUpdates();
  var user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await Shop.loadAll();

    var group = Group.findUserGroup(user.uid);
    if (group == null) {
      FirebaseAuth.instance.signOut();
      // localization not initialized at this point
      Fluttertoast.showToast(
        msg: 'Profile corrupted: Not asssociated with a group',
        toastLength: Toast.LENGTH_LONG,
      );
    } else {
      // get username
      var userSnapshot = await Database.realtime
          .child('groups/${group.groupId}/users/${user.uid}')
          .get();
      if (userSnapshot.value == null) {
        FirebaseAuth.instance.signOut();
        Fluttertoast.showToast(
          msg: 'Profile corrupted: Username not specified',
          toastLength: Toast.LENGTH_LONG,
        );
      } else {
        validUser = true;
      }
    }
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  Logger.level = Level.debug;
  runApp(
    EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('de'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: PizzaFlizzaApp(isValidUser: validUser)),
  );
}

class PizzaFlizzaApp extends StatefulWidget {
  final bool isValidUser;

  const PizzaFlizzaApp({super.key, required this.isValidUser});

  @override
  State<StatefulWidget> createState() => _PizzaFlizzaAppState();
}

class _PizzaFlizzaAppState extends State<PizzaFlizzaApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late StreamSubscription<User?> _authStateChangedSubscription;

  // based on: https://dev.to/snowcodes/flutter-firebase-authentication-dynamic-routing-by-authstatechanges-9k0
  void _onAuthStateChanged(User? user) async {
    if (user == null) {
      _deinitializeUser();
    }
  }

  void _initializeUser() {
    Shop.initializeUserGroupUpdates();
    _navigatorKey.currentState?.pushReplacementNamed('home');
  }

  void _deinitializeUser() {
    Database.userId = null;

    // listeners already canceled before signing out
    _navigatorKey.currentState?.pushReplacementNamed('login');
  }

  @override
  void initState() {
    super.initState();

    _authStateChangedSubscription =
        FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);

    Group.initializeGroupUpdates().then((_) async {
      var user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var group = Group.findUserGroup(user.uid);
        if (group == null) {
          FirebaseAuth.instance.signOut();
          Fluttertoast.showToast(
            msg: 'login.errors.no_group_create'.tr(),
            toastLength: Toast.LENGTH_LONG,
          );
          _navigatorKey.currentState?.pushReplacementNamed('login');
        } else {
          // get username
          var userSnapshot = await Database.realtime
              .child('groups/${group.groupId}/users/${user.uid}')
              .get();
          if (userSnapshot.value == null) {
            FirebaseAuth.instance.signOut();
            Fluttertoast.showToast(
              msg: 'login.errors.no_username_create'.tr(),
              toastLength: Toast.LENGTH_LONG,
            );
            _navigatorKey.currentState?.pushReplacementNamed('login');
          } else {
            _loadUserData(user, userSnapshot.value as String, group);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _authStateChangedSubscription.cancel();
    Group.cancelGroupUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PizzaFlizza',
      theme: Themes.darkTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      navigatorKey: _navigatorKey,
      initialRoute: widget.isValidUser ? 'home' : 'login',
      onGenerateRoute: (settings) {
        Widget widget;

        switch (settings.name) {
          case 'login':
            widget = LoginPage(
              onLoginComplete: _loadUserData,
            );
            break;
          case 'intro':
            widget = IntroPage(
              onIntroComplete: (groupName, groupId) async {
                var user = FirebaseAuth.instance.currentUser;
                var userName = Database.userName;
                if (user == null || userName == null) {
                  _navigatorKey.currentState?.pushReplacementNamed('login');
                  return;
                }

                var group = await Group.joinGroup(
                  groupName,
                  groupId,
                  user.uid,
                  userName,
                );

                _loadUserData(user, userName, group);
              },
            );
            break;
          default:
            widget = const HomePage();
            break;
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => widget,
        );
      },
    );
  }

  Future<void> _loadUserData(User user, String userName, Group? group) async {
    Database.userId = user.uid;
    Database.userName = userName;
    Database.userEmail = user.email;
    Database.providerId = user.providerData.firstOrNull?.providerId;

    if (group == null) {
      _navigatorKey.currentState?.pushReplacementNamed('intro');
      return;
    }

    Database.groupId = group.groupId;
    Database.groupName = group.groupName;

    var userSnapshot = await Database.realtime
        .child('groups/${group.groupId}/users/${user.uid}')
        .get();
    if (userSnapshot.value == null) {
      FirebaseAuth.instance.signOut();
      Fluttertoast.showToast(
        msg: 'login.errors.no_username_create'.tr(),
        toastLength: Toast.LENGTH_LONG,
      );
    } else {
      Database.userName = userSnapshot.value as String;
      Shop.initializeUserGroupUpdates();
      await Shop.loadAll();
      _initializeUser();
    }
  }
}
