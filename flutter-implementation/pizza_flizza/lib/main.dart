import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pizza_flizza/pages/login_page.dart';
import 'package:pizza_flizza/theme.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

    FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'wanja.wischmeier@gmail.com',
      password: 'testing2',
    );

    // based on: https://dev.to/snowcodes/flutter-firebase-authentication-dynamic-routing-by-authstatechanges-9k0
    _sub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _navigatorKey.currentState!.pushReplacementNamed(
        user == null ? 'login' : 'home',
      );
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
          case 'home':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const HomePage(),
            );
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
