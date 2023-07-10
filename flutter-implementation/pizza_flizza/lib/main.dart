import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logger/logger.dart';

import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/group.dart';
import 'package:pizza_flizza/database/orders/order_parser.dart';
import 'package:pizza_flizza/database/shop.dart';
import 'package:pizza_flizza/database/user.dart';
import 'package:pizza_flizza/other/firebase_options.dart';
import 'package:pizza_flizza/pages/home_page/home_page.dart';
import 'package:pizza_flizza/pages/intro_page/intro_page.dart';
import 'package:pizza_flizza/pages/login_page/login_page.dart';
import 'package:pizza_flizza/other/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Group.initializeListeners();
  var route = await _PizzaFlizzaAppState.initializeUser(
    null,
    null,
    null,
    reroute: false,
  );

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
      child: PizzaFlizzaApp(initialPage: route),
    ),
  );
}

class PizzaFlizzaApp extends StatefulWidget {
  final String initialPage;

  const PizzaFlizzaApp({super.key, required this.initialPage});

  @override
  State<StatefulWidget> createState() => _PizzaFlizzaAppState();
}

class _PizzaFlizzaAppState extends State<PizzaFlizzaApp> {
  static final _navigatorKey = GlobalKey<NavigatorState>();
  late StreamSubscription<User?> _authStateChangedSubscription;
  late StreamSubscription<Map<int, Group>> _groupsUpdatedSubscription;
  static String? _currentUserName;

  // based on: https://dev.to/snowcodes/flutter-firebase-authentication-dynamic-routing-by-authstatechanges-9k0
  void _onAuthStateChanged(User? user) async {
    if (user == null) {
      _deinitializeUser();
    }
  }

  static Future<String> initializeUser(
    User? firebaseUser,
    String? userName,
    Group? group, {
    bool reroute = true,
  }) async {
    _currentUserName ??= userName;

    if (firebaseUser == null) {
      firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        if (reroute) {
          _navigatorKey.currentState?.pushReplacementNamed('login');
        }
        return 'login';
      }
    }

    if (group == null) {
      group = Group.findUserGroup(firebaseUser.uid);
      if (group == null) {
        if (reroute) {
          _navigatorKey.currentState?.pushReplacementNamed('intro');
        }
        return 'intro';
      }
    }

    if (userName == null) {
      userName = group.users[firebaseUser.uid];
      userName ??= firebaseUser.displayName;
      if (userName == null) {
        firebaseUser.delete();
        Fluttertoast.showToast(
          msg: 'login.errors.no_username_create'.tr(),
          toastLength: Toast.LENGTH_LONG,
        );
        if (reroute) {
          _navigatorKey.currentState?.pushReplacementNamed('login');
        }
        return 'login';
      }
    }

    Database.groupUsers = await UserData.loadUsersInGroup(group);
    Database.currentUser = UserData.fromFirebaseUser(
      firebaseUser,
      userName,
      group,
    );
    await Shop.initializeShops();
    OrderParser.initializeUserGroupUpdates();

    if (reroute) {
      _navigatorKey.currentState?.pushReplacementNamed('home');
    }
    return 'home';
  }

  void _deinitializeUser() {
    // Database.currentUser = null;

    // listeners already canceled before signing out
    _navigatorKey.currentState?.pushReplacementNamed('login');
  }

  @override
  void initState() {
    super.initState();

    _authStateChangedSubscription =
        FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);

    // trigger intro if the user is no longer associated with a group
    _groupsUpdatedSubscription = Group.subscribeToGroupsUpdated((groups) {
      var firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        return;
      }

      if (Group.findUserGroup(firebaseUser.uid) == null) {
        _navigatorKey.currentState?.pushReplacementNamed('intro');
      }
    });
  }

  @override
  void dispose() {
    _authStateChangedSubscription.cancel();
    _groupsUpdatedSubscription.cancel();
    Group.cancelGroupListeners();
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
      initialRoute: widget.initialPage,
      onGenerateRoute: (settings) {
        Widget widget;

        switch (settings.name) {
          case 'login':
            widget = const LoginPage(
              onLoginComplete: initializeUser,
            );
            break;
          case 'intro':
            widget = IntroPage(
              onIntroCanceled: () {
                _navigatorKey.currentState?.pushReplacementNamed('login');
              },
              onIntroComplete: (groupName, groupId) async {
                var firebaseUser = FirebaseAuth.instance.currentUser;
                if (firebaseUser == null) {
                  _navigatorKey.currentState?.pushReplacementNamed('login');
                  return;
                }

                _currentUserName ??= firebaseUser.displayName;
                if (_currentUserName == null) {
                  firebaseUser.delete();
                  Fluttertoast.showToast(
                    msg: 'login.errors.no_username_create'.tr(),
                    toastLength: Toast.LENGTH_LONG,
                  );
                  _navigatorKey.currentState?.pushReplacementNamed('login');
                  return;
                }

                var group = await Group.joinGroup(
                  groupName,
                  groupId,
                  firebaseUser.uid,
                  _currentUserName!,
                );

                initializeUser(
                  firebaseUser,
                  _currentUserName!,
                  group,
                );
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
}
