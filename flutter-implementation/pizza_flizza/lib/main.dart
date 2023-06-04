import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/shop.dart';
import 'package:pizza_flizza/firebase_options.dart';
import 'package:pizza_flizza/pages/home_page.dart';
import 'package:pizza_flizza/pages/login_page.dart';
import 'package:pizza_flizza/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  runApp(const PizzaFlizzaApp());
}

class PizzaFlizzaApp extends StatefulWidget {
  const PizzaFlizzaApp({super.key});

  @override
  State<StatefulWidget> createState() => _PizzaFlizzaAppState();
}

class _PizzaFlizzaAppState extends State<PizzaFlizzaApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late StreamSubscription<User?> _sub;

  @override
  void initState() {
    super.initState();

    // based on: https://dev.to/snowcodes/flutter-firebase-authentication-dynamic-routing-by-authstatechanges-9k0
    _sub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _navigatorKey.currentState?.pushReplacementNamed('login');
      } else {
        Database.groupId = 'prenski_12';
        Database.userId = user.uid;

        Shop.loadAll().then((value) =>
            _navigatorKey.currentState?.pushReplacementNamed('home'));
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: Themes.darkTheme,
      debugShowCheckedModeBanner: false,
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
