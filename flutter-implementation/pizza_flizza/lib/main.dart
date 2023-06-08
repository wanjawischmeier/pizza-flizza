import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/shop.dart';
import 'package:pizza_flizza/other/firebase_options.dart';
import 'package:pizza_flizza/pages/home_page/home_page.dart';
import 'package:pizza_flizza/pages/login_page/login_page.dart';
import 'package:pizza_flizza/other/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  String? uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    Database.groupId = 'prenski_12';
    Database.userId = uid;

    await Shop.loadAll();
  }

  Logger.level = Level.debug;
  runApp(
    EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('de'),
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

  void _initializeUser() {
    // based on: https://dev.to/snowcodes/flutter-firebase-authentication-dynamic-routing-by-authstatechanges-9k0
    authStateChangedInitialized(User? user) async {
      if (user == null) {
        Database.userEmail = null;
        _deinitializeUser();
      } else if (Database.userEmail == null) {
        Database.groupId = 'prenski_12';
        Database.userId = user.uid;
        Database.userEmail = user.email;

        // user.providerData.firstOrNull?.displayName
        if (user.providerData.isNotEmpty) {
          Database.providerId = user.providerData.first.providerId;
        }

        var snapshot = await Database.userReference.child('name').get();
        if (snapshot.value != null) {
          Database.userName = snapshot.value as String;
        }

        await Shop.loadAll();
        _navigatorKey.currentState?.pushReplacementNamed('home');
      }
    }

    _authStateChangedSubscription = FirebaseAuth.instance
        .authStateChanges()
        .listen(authStateChangedInitialized);
  }

  Future<void> _deinitializeUser() async {
    authStateChangedDeinitialized(User? user) {
      if (user != null) {
        _initializeUser();
      }
    }

    await Shop.cancelSubscriptions();
    await _authStateChangedSubscription.cancel();
    _authStateChangedSubscription = FirebaseAuth.instance
        .authStateChanges()
        .listen(authStateChangedDeinitialized);
    _navigatorKey.currentState?.pushReplacementNamed('login');
  }

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  @override
  void dispose() {
    _authStateChangedSubscription.cancel();
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
        switch (settings.name) {
          case 'login':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const LoginPage(),
            );
          default:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const HomePage(),
            );
        }
      },
    );
  }
}
