import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/shop.dart';
import 'package:pizza_flizza/other/theme.dart';
import 'package:pizza_flizza/paypal/paypal_payment.dart';

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
      (Database.providerId == 'password')
          ? ''
          : ' (specified by ${Database.providerId})';
  String? _email = Database.userEmail;
  String? _userName = Database.userName;
  String _groupId = Database.groupId;

  bool _userNameChanging = false;
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
                          onFocusChange: _onGroupChanged,
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
                            enabled: !_groupIdChanging,
                            onChanged: (value) => _groupId = value,
                          ),
                        ),
                        const SizedBox(height: _itemSpacer),
                        TextButton(
                          onPressed: (_email == null)
                              ? null
                              : () {
                                  FirebaseAuth.instance
                                      .sendPasswordResetEmail(email: _email!)
                                      .then((value) {
                                    Fluttertoast.showToast(
                                      msg:
                                          'An email to reset the password has been send to your inbox',
                                      toastLength: Toast.LENGTH_LONG,
                                    );
                                  }).catchError(
                                    (error) {
                                      Fluttertoast.showToast(
                                        msg:
                                            'Failed to send password reset email',
                                        toastLength: Toast.LENGTH_LONG,
                                      );
                                    },
                                  );
                                },
                          child: const Text(
                            'Reset password',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Payment.processPayment("sb-1nk43y26329305@business.example.com", 12);
                          },
                          child: const Text(
                            'Make Payment',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            widget.onRemoveOverlay();

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    PaypalPayment(
                                  onFinish: (number) async {
                                    // payment done
                                    print('order id: ' + number);
                                  },
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Pay with Paypal',
                            textAlign: TextAlign.center,
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
      // clarify that an update is being applied
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _userNameChanging = false;
      });
    }
  }

  Future<void> _onGroupChanged(bool hasFocus) async {
    if (!hasFocus && (_groupId.isNotEmpty) && _groupId != Database.groupId) {
      setState(() {
        _groupIdChanging = true;
      });

      var oldReference = Database.userReference;
      var snapshot = await oldReference.get();
      Database.groupId = _groupId;
      await Database.userReference.set(snapshot.value);
      await oldReference.remove();

      Shop.cancelGroupSubscriptions();
      Shop.subscribeToGroupEvents();

      // clarify that an update is being applied
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _groupIdChanging = false;
      });
    }
  }
}
