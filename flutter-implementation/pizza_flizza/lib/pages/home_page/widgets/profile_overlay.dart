import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/other/theme.dart';

typedef OnRemoveOverlay = void Function();

class ProfileOverlay extends StatefulWidget {
  final OnRemoveOverlay onRemoveOverlay;

  const ProfileOverlay({super.key, required this.onRemoveOverlay});

  @override
  State<ProfileOverlay> createState() => _ProfileOverlayState();
}

class _ProfileOverlayState extends State<ProfileOverlay> {
  static const double _itemSpacer = 16;
  final String _thirdPartyProviderHintEmail =
      ' (specified by ${Database.providerId})';
  String? _email = Database.userEmail;
  String? _userName = Database.userName;
  String _password = '';
  String _groupId = Database.groupId;

  bool _emailChanging = false;
  bool _userNameChanging = false;
  bool _passwordChanging = false;
  bool _groupIdChanging = false;

  final _textProgress = const SizedBox(
    width: 14,
    height: 14,
    child: CircularProgressIndicator(
      strokeWidth: 2,
    ),
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: Themes.grayMid,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Your Profile',
                    style: TextStyle(
                      fontSize: 24,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                    child: Column(
                      children: [
                        Focus(
                          onFocusChange: _onUserNameChanged,
                          child: TextField(
                            decoration: InputDecoration(
                              suffix: _userNameChanging ? _textProgress : null,
                              border: const OutlineInputBorder(),
                              labelText: 'Username',
                            ),
                            textInputAction: TextInputAction.done,
                            controller: TextEditingController(
                              text: _userName,
                            ),
                            enabled: !_userNameChanging,
                            onChanged: (value) => _userName = value,
                          ),
                        ),
                        const SizedBox(height: _itemSpacer),
                        Focus(
                          onFocusChange: (hasFocus) {
                            if (!hasFocus) {
                              print('lost group focus');
                            }
                          },
                          child: TextField(
                            decoration: InputDecoration(
                              suffix: _emailChanging ? _textProgress : null,
                              border: const OutlineInputBorder(),
                              labelText: 'Email$_thirdPartyProviderHintEmail',
                            ),
                            textInputAction: TextInputAction.done,
                            controller: TextEditingController(
                              text: _email,
                            ),
                            enabled: Database.providerId == null,
                            onChanged: (value) => _email = value,
                          ),
                        ),
                        const SizedBox(height: _itemSpacer),
                        Focus(
                          onFocusChange: (hasFocus) {
                            if (!hasFocus) {
                              print('lost group focus');
                            }
                          },
                          child: TextField(
                            decoration: InputDecoration(
                              suffix: _groupIdChanging ? _textProgress : null,
                              border: const OutlineInputBorder(),
                              labelText: 'Group',
                            ),
                            textInputAction: TextInputAction.done,
                            controller: TextEditingController(
                              text: _groupId,
                            ),
                            enabled: false,
                            onChanged: (value) => _groupId = value,
                          ),
                        ),
                        const SizedBox(height: _itemSpacer),
                        Focus(
                          onFocusChange: (hasFocus) {
                            if (!hasFocus) {
                              print('lost group focus');
                            }
                          },
                          child: TextField(
                            decoration: InputDecoration(
                              suffix: _passwordChanging ? _textProgress : null,
                              border: const OutlineInputBorder(),
                              labelText: 'Password',
                            ),
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            controller: TextEditingController(
                              text: _password,
                            ),
                            enabled: false,
                            onChanged: (value) => _password = value,
                          ),
                        ),
                      ],
                    )),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Themes.grayLight,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // sign out logic is handled by listener in main
                          FirebaseAuth.instance.signOut().then((value) {
                            widget.onRemoveOverlay();
                          });
                        },
                        child: const Text(
                          'Log out',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Themes.cream,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: widget.onRemoveOverlay,
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onUserNameChanged(bool hasFocus) async {
    if (!hasFocus &&
        (_userName?.isNotEmpty ?? false) &&
        _userName != Database.userName) {
      setState(() {
        _userNameChanging = true;
      });

      Database.userName = _userName;
      await Database.userReference.child('name').set(_userName);
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _userNameChanging = false;
      });
    }
  }
}
