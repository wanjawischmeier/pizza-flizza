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

  if (FirebaseAuth.instance.currentUser != null) {
    await Shop.loadAll();
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
          // Locale('de'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const PizzaFlizzaApp()),
  );
}

class PizzaFlizzaApp extends StatefulWidget {
  const PizzaFlizzaApp({super.key});

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

    Group.initializeGroupUpdates().then((value) {
      var user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _loadUserData(user, null);
      }

      _authStateChangedSubscription =
          FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
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
      initialRoute:
          FirebaseAuth.instance.currentUser == null ? 'login' : 'home',
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
              onIntroComplete: () {
                _navigatorKey.currentState?.pushReplacementNamed('home');
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

  Future<void> _loadUserData(User user, Group? group) async {
    // find group associated with user
    if (group == null) {
      group = Group.findUserGroup(user.uid);
      if (group == null) {
        Fluttertoast.showToast(
          msg: 'login.errors.no_group_create'.tr(),
          toastLength: Toast.LENGTH_LONG,
        );
        await FirebaseAuth.instance.signOut();
        _deinitializeUser();
        return;
      }
    }

    Database.userId = user.uid;
    Database.userEmail = user.email;
    Database.groupId = group.groupId;
    Database.groupName = group.groupName;
    Database.providerId = user.providerData.firstOrNull?.providerId;

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
      _navigatorKey.currentState?.pushReplacementNamed('intro');
    }
  }
}
