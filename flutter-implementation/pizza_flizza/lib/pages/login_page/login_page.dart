import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:pizza_flizza/database/group.dart';
import 'package:pizza_flizza/other/custom_icons.dart';
import 'package:pizza_flizza/other/logger.util.dart';
import 'package:pizza_flizza/other/theme.dart';
import 'package:pizza_flizza/pages/login_page/widgets/google_signin_button.dart';
import 'package:pizza_flizza/pages/login_page/widgets/group_selection_dialog.dart';
import 'package:pizza_flizza/widgets/group_selection_field.dart';

typedef OnLoginComplete = void Function(User user, Group? group);

class LoginPage extends StatefulWidget {
  final OnLoginComplete? onLoginComplete;

  const LoginPage({super.key, this.onLoginComplete});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final log = AppLogger();

  // taken from: https://stackoverflow.com/a/50663835/13215204
  final _emailRegEx = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );
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
        title: const Text("login.page_title").tr(),
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
                              labelText: 'login.fields.email.title'.tr(),
                              errorText: _emailError,
                              hintText: _loginMode
                                  ? 'login.fields.email.hint_login'.tr()
                                  : 'login.fields.email.hint_create'.tr(),
                            ),
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
                                      labelText: 'login.fields.username.title',
                                      errorText: _userNameError,
                                      hintText: _loginMode
                                          ? 'login.fields.username.hint_login'
                                          : 'login.fields.username.hint_create',
                                    ),
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
                                    onSelectionConfirmed: (groupName, groupId) {
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
                              labelText: 'login.fields.password.title'.tr(),
                              errorText: _passwordError,
                              hintText: _loginMode
                                  ? 'login.fields.password.hint_login'.tr()
                                  : 'login.fields.password.hint_create'.tr(),
                            ),
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
                                      _loginMode
                                          ? 'login.actions.mode_switch.create'
                                              .tr()
                                          : 'login.actions.mode_switch.log_in'
                                              .tr(),
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
                                    child: Text(
                                      'login.actions.forgot_password.header'
                                          .tr(),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 15,
                                      ),
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
                            onPressed: _isLoading ? null : _checkForm,
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
                                    _loginMode
                                        ? 'login.actions.go.log_in'.tr()
                                        : 'login.actions.go.create'.tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                    ),
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
                          onGoogleSignInComplete: (user) async {
                            if (user.email == null) {
                              Fluttertoast.showToast(
                                msg: 'login.errors.no_email_google'.tr(),
                              );

                              await FirebaseAuth.instance.signOut();
                              setState(() {
                                _isLoading = false;
                              });
                              return;
                            }

                            if (user.displayName == null) {
                              Fluttertoast.showToast(
                                msg: 'login.errors.no_username_google'.tr(),
                              );

                              await FirebaseAuth.instance.signOut();
                              setState(() {
                                _isLoading = false;
                              });
                              return;
                            }

                            var group = Group.findUserGroup(user.uid);
                            if (group == null) {
                              bool? success = await showDialog(
                                context: context,
                                builder: ((context) {
                                  return GroupSelectionDialog(
                                    onSelectionConfirmed: (groupName, groupId) {
                                      _groupName = groupName;
                                      _groupId = groupId;
                                      Navigator.of(context).pop(true);
                                    },
                                  );
                                }),
                              );

                              if (success == null) {
                                await FirebaseAuth.instance.signOut();
                                setState(() {
                                  _isLoading = false;
                                });
                                return;
                              }

                              var group = await Group.joinGroup(
                                _groupName,
                                _groupId,
                                user.uid,
                                user.displayName!,
                              );
                              _groupId = group.groupId;

                              widget.onLoginComplete?.call(user, group);
                            } else {
                              _groupName = group.groupName;
                              _groupId = group.groupId;

                              widget.onLoginComplete?.call(user, group);
                            }
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
    if (_email.isEmpty) {
      _emailError = 'login.errors.no_email'.tr();
      error = true;
    } else if (!_emailRegEx.hasMatch(_email)) {
      _emailError = 'login.errors.invalid_email'.tr();
      error = true;
    }

    // check username when creating account
    if (!_loginMode) {
      if (_userName.isEmpty) {
        _userNameError = 'login.errors.no_username'.tr();
        error = true;
      } else if (_userName.length < 6) {
        _userNameError = 'login.errors.invalid_username'.tr();
        error = true;
      }

      if (_groupName.isEmpty) {
        _groupNameError = 'login.errors.no_group_name'.tr();
        error = true;
      }
    }

    // check password
    if (_password.isEmpty) {
      _passwordError = 'login.errors.no_password'.tr();
      error = true;
    } else if (_password.length < 6) {
      // firebase auth only requires passwords to be at least 6 characters
      _passwordError = 'login.errors.invalid_password'.tr();
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

    UserCredential? credential;

    try {
      credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: _email, password: _password);
    } catch (error) {
      String code = (error as FirebaseAuthException).code;
      String pattern = 'login.errors.firebase_auth.$code';
      String message = pattern.tr();
      if (message == pattern) {
        message = 'login.errors.firebase_auth.default'.tr();
      }

      switch (code) {
        case 'user-not-found':
          setState(() {
            _emailError = message;
          });
          break;
        case 'wrong-password':
          setState(() {
            _passwordError = message;
          });
          break;
        default:
          Fluttertoast.showToast(
            msg: message,
          );
      }
    }

    if (credential != null) {
      User? user = credential.user;
      String? email = user?.email;

      if (user == null) {
        Fluttertoast.showToast(
          msg: 'login.errors.no_credentials_create'.tr(),
        );

        await FirebaseAuth.instance.signOut();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (email == null) {
        Fluttertoast.showToast(
          msg: 'login.errors.no_email_create'.tr(),
        );

        await FirebaseAuth.instance.signOut();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // find group associated with user
      var group = Group.findUserGroup(user.uid);
      if (group == null) {
        FirebaseAuth.instance.signOut();
        Fluttertoast.showToast(
          msg: 'login.errors.no_group_create'.tr(),
          toastLength: Toast.LENGTH_LONG,
        );
      } else {
        _groupId = group.groupId;
        widget.onLoginComplete?.call(user, group);
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

    UserCredential? credential;

    try {
      credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: _email, password: _password);
    } catch (error) {
      String code = (error as FirebaseAuthException).code;
      String pattern = 'login.errors.firebase_auth.$code';
      String message = pattern.tr();
      if (message == pattern) {
        message = 'login.errors.firebase_auth.default'.tr();
      }

      switch (code) {
        case 'email-already-in-use':
          setState(() {
            _emailError = message;
          });
          break;
        default:
          Fluttertoast.showToast(
            msg: message,
          );
      }
    }

    if (credential != null) {
      User? user = credential.user;
      String? email = user?.email;

      if (user == null) {
        Fluttertoast.showToast(
          msg: 'login.errors.no_credentials_create'.tr(),
        );

        await FirebaseAuth.instance.signOut();
      } else if (email == null) {
        Fluttertoast.showToast(
          msg: 'login.errors.no_email_create'.tr(),
        );

        await FirebaseAuth.instance.signOut();
        setState(() {
          _isLoading = false;
        });
        return;
      } else {
        var group = await Group.joinGroup(
          _groupName,
          _groupId,
          user.uid,
          _userName,
        );

        _groupId = group.groupId;
        widget.onLoginComplete?.call(user, group);
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _resetPassword() {
    // check email
    if (_email.isEmpty) {
      setState(() {
        _emailError = 'login.errors.no_email'.tr();
      });
      return;
    } else if (!_emailRegEx.hasMatch(_email)) {
      setState(() {
        _emailError = 'login.errors.invalid_email'.tr();
      });
      return;
    }

    FirebaseAuth.instance.sendPasswordResetEmail(email: _email).then((value) {
      Fluttertoast.showToast(
        msg: 'login.actions.forgot_password.send'.tr(),
        toastLength: Toast.LENGTH_LONG,
      );
    }).catchError(
      (error) {
        Fluttertoast.showToast(
          msg: 'login.actions.forgot_password.failed'.tr(),
          toastLength: Toast.LENGTH_LONG,
        );
      },
    );
  }
}
