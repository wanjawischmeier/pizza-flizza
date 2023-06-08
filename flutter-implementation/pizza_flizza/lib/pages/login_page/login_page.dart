import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/other/custom_icons.dart';
import 'package:pizza_flizza/other/logger.util.dart';
import 'package:pizza_flizza/other/theme.dart';
import 'package:pizza_flizza/pages/login_page/widgets/google_signin_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final log = AppLogger();

  static const String _groupId = 'prenski_12';
  bool _isLoading = false;
  String _email = '';
  String _userName = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Themes.grayDark,
      appBar: AppBar(
        title: const Text("Login Page"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Column(children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Center(
                  child: Container(
                    width: 200,
                    height: 150,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Themes.grayMid,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        )
                      ],
                    ),
                    child: const FittedBox(
                      child: Icon(
                        PizzaIcons.logo,
                        color: Themes.cream,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Email',
                      hintText: 'Enter valid email id as abc@gmail.com'),
                  textInputAction: TextInputAction.next,
                  enabled: false,
                  onChanged: (value) => _email = value,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 15.0, right: 15.0, top: 15, bottom: 0),
                child: TextField(
                  obscureText: true,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Password',
                      hintText: 'Enter secure password'),
                  textInputAction: TextInputAction.done,
                  enabled: false,
                  onChanged: (value) => _password = value,
                  onSubmitted: (value) => _signInWithEmail(),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: FORGOT PASSWORD SCREEN GOES HERE
                },
                child: const Text(
                  'Forgot Password',
                  style: TextStyle(color: Colors.blue, fontSize: 15),
                ),
              ),
              Container(
                height: 50,
                width: 250,
                decoration: BoxDecoration(
                    color: _isLoading ? Colors.lightBlueAccent : Colors.blue,
                    borderRadius: BorderRadius.circular(20)),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Themes.grayLight,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {}, //_signInWithEmail,
                  child: _isLoading
                      ? const SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(color: Colors.white, fontSize: 25),
                        ),
                ),
              ),
            ]),
            GoogleSignInButton(
              onGoogleSignInComplete: (displayName, user) {
                _initializeDatabaseIfNeeded(_groupId, user.uid, displayName);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _signInWithEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: _email, password: _password);
    } catch (error) {
      log.e('error');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createAccountWithEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: _email, password: _password);
      User? user = credential.user;
      if (user == null) {
        await FirebaseAuth.instance.signOut();
        return;
      }

      _initializeDatabaseIfNeeded(_groupId, user.uid, _userName);
    } catch (error) {
      log.e('error');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _initializeDatabaseIfNeeded(
      String groupId, String userId, String userName) async {
    var userReference = Database.realtime.child('users/$groupId/$userId');

    var snapshot = (await userReference.once()).snapshot;
    if (snapshot.value == null) {
      Database.userName = userName;
      await userReference.set({
        'name': userName,
      });
    }
  }
}