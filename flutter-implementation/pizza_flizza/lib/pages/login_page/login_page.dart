import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/other/custom_icons.dart';
import 'package:pizza_flizza/other/logger.util.dart';
import 'package:pizza_flizza/other/theme.dart';
import 'package:pizza_flizza/pages/login_page/widgets/google_signin_button.dart';
import 'package:pizza_flizza/widgets/group_selection_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final log = AppLogger();

  // taken from: https://stackoverflow.com/a/50663835/13215204
  final _emailRegEx = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  bool _isLoading = false;
  bool _loginMode = true;
  String _email = '';
  String _userName = '';
  int? _groupId;
  String _groupName = '';
  String _password = '';
  String? _emailError;
  String? _userNameError;
  String? _groupNameError;
  String? _passwordError;

  final GlobalKey<GroupSelectionFieldState> _groupSelectionKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Themes.grayDark,
      appBar: AppBar(
        title: const Text("Login Page"),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints viewportConstraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: viewportConstraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 32),
                              child: Container(
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
                        ],
                      ),
                      Column(children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: TextField(
                            decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Email',
                                errorText: _emailError,
                                hintText: _loginMode
                                    ? 'Enter your email'
                                    : 'Enter a valid email'),
                            textInputAction: TextInputAction.next,
                            onChanged: (value) {
                              _email = value;

                              setState(() {
                                _emailError = null;
                              });
                            },
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.fastOutSlowIn,
                          child: _loginMode
                              ? const SizedBox()
                              : Padding(
                                  padding: const EdgeInsets.only(
                                      left: 15.0,
                                      right: 15.0,
                                      top: 15,
                                      bottom: 0),
                                  child: TextField(
                                    decoration: InputDecoration(
                                        border: const OutlineInputBorder(),
                                        labelText: 'Username',
                                        errorText: _userNameError,
                                        hintText: _loginMode
                                            ? 'Enter your username'
                                            : 'Choose a valid username'),
                                    textInputAction: TextInputAction.next,
                                    onChanged: (value) {
                                      _userName = value;

                                      setState(() {
                                        _userNameError = null;
                                      });
                                    },
                                  ),
                                ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.fastOutSlowIn,
                          child: _loginMode
                              ? const SizedBox()
                              : Padding(
                                  padding: const EdgeInsets.only(
                                      left: 15.0,
                                      right: 15.0,
                                      top: 15,
                                      bottom: 0),
                                  child: GroupSelectionField(
                                    error: _groupNameError,
                                    onGroupNameChanged: (groupName, groupId) {
                                      if (_groupNameError != null) {
                                        setState(() {
                                          _groupNameError = null;
                                        });
                                      }
                                      _groupName = groupName;
                                      _groupId = groupId;
                                    },
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 15.0, right: 15.0, top: 15, bottom: 0),
                          child: TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Password',
                                errorText: _passwordError,
                                hintText: _loginMode
                                    ? 'Enter your password'
                                    : 'Enter a secure password'),
                            textInputAction: TextInputAction.done,
                            onChanged: (value) {
                              _password = value;

                              setState(() {
                                _passwordError = null;
                              });
                            },
                            onSubmitted: (value) => _checkForm(),
                          ),
                        ),
                        IntrinsicHeight(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _groupName = '';
                                        _emailError = null;
                                        _userNameError = null;
                                        _passwordError = null;
                                        _groupNameError = null;

                                        _groupSelectionKey.currentState
                                            ?.reset();

                                        _loginMode = !_loginMode;
                                      });
                                    },
                                    child: Text(
                                      _loginMode ? 'Create Account' : 'Log in',
                                      style: const TextStyle(
                                          color: Colors.blue, fontSize: 15),
                                    ),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: VerticalDivider(
                                  thickness: 1,
                                  color: Themes.grayLight,
                                ),
                              ),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: _resetPassword,
                                    child: const Text(
                                      'Forgot Password',
                                      style: TextStyle(
                                          color: Colors.blue, fontSize: 15),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 50,
                          width: 250,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Themes.grayLight,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _checkForm,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 25,
                                    width: 25,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                    _loginMode ? 'Log in' : 'Create',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 25),
                                  ),
                          ),
                        ),
                      ]),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.fastOutSlowIn,
                        padding: const EdgeInsets.only(top: 40),
                        height: _loginMode ? 120 : 0,
                        child: GoogleSignInButton(
                          onGoogleSignInComplete: (displayName, user) {
                            showDialog(
                              context: context,
                              builder: ((context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: Themes.grayMid,
                                  title: const Text('Join a group'),
                                  content: GroupSelectionField(
                                    autofocus: true,
                                    onSelectionConfirmed: (groupName, groupId) {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                );
                              }),
                            );

                            _initializeDatabaseIfNeeded(
                              _groupName,
                              user.uid,
                              displayName,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _checkForm() {
    bool error = false;

    // check email
    if (_email == '') {
      _emailError = 'Please enter an email';
      error = true;
    } else if (!_emailRegEx.hasMatch(_email)) {
      _emailError = 'Please enter a valid email';
      error = true;
    }

    // check username when creating account
    if (!_loginMode) {
      if (_userName == '') {
        _userNameError = 'Please enter an username';
        error = true;
      } else if (_userName.length < 6) {
        _userNameError = 'Please enter at least 6 characters';
        error = true;
      }

      if (_groupName == '') {
        _groupNameError = 'Please enter a group id';
        error = true;
      }
    }

    // check password
    if (_password == '') {
      _passwordError = 'Please enter a password';
      error = true;
    } else if (_password.length < 6) {
      // firebase auth only requires passwords to be at least 6 characters
      _passwordError = 'Please enter at least 6 characters';
      error = true;
    }

    if (error) {
      setState(() {});
      return;
    }

    if (_loginMode) {
      _signInWithEmail();
    } else {
      _createAccountWithEmail();
    }
  }

  void _signInWithEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: _email, password: _password);
    } catch (error) {
      switch ((error as FirebaseAuthException).code) {
        case 'user-not-found':
          setState(() {
            _emailError = 'Unknown email, try creating an account';
          });
          break;
        case 'wrong-password':
          setState(() {
            _passwordError = 'Incorrect password';
          });
          break;
        case 'too-many-requests':
          Fluttertoast.showToast(
            msg: 'Too many requests, try again later',
          );
          break;
        default:
          Fluttertoast.showToast(
            msg: 'Unknown error',
          );
      }
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
        Fluttertoast.showToast(
          msg: 'Failed to get account credentials',
        );

        await FirebaseAuth.instance.signOut();
        return;
      }

      _initializeDatabaseIfNeeded(_groupName, user.uid, _userName);
    } catch (error) {
      switch ((error as FirebaseAuthException).code) {
        case 'email-already-in-use':
          setState(() {
            _emailError = 'Email already used, try logging in';
          });
          break;
        default:
          Fluttertoast.showToast(
            msg: 'Unknown error',
          );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _resetPassword() {
    // check email
    if (_email == '') {
      setState(() {
        _emailError = 'Please enter an email';
      });
      return;
    } else if (!_emailRegEx.hasMatch(_email)) {
      setState(() {
        _emailError = 'Please enter a valid email';
      });
      return;
    }

    FirebaseAuth.instance.sendPasswordResetEmail(email: _email).then((value) {
      Fluttertoast.showToast(
        msg: 'An email to reset the password has been send to your inbox',
        toastLength: Toast.LENGTH_LONG,
      );
    }).catchError(
      (error) {
        Fluttertoast.showToast(
          msg: 'Failed to send password reset email',
          toastLength: Toast.LENGTH_LONG,
        );
      },
    );
  }

  Future<void> _initializeDatabaseIfNeeded(
      String groupId, String userId, String userName) async {
    var userReference = Database.realtime.child('users/$groupId/$userId');
    var lookupReference = Database.realtime.child('user_lookup/$userId');

    var snapshot = (await userReference.once()).snapshot;
    if (snapshot.value == null) {
      Database.userName = userName;
      await userReference.set({
        'name': userName,
      });
    }

    snapshot = (await lookupReference.once()).snapshot;
    if (snapshot.value == null) {
      Database.groupId = groupId;
      await lookupReference.set(groupId);
    }
  }
}
