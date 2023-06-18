import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/group.dart';
import 'package:pizza_flizza/database/shop.dart';
import 'package:pizza_flizza/other/theme.dart';
import 'package:pizza_flizza/widgets/group_selection_field.dart';

typedef OnRemoveOverlay = void Function();

class ProfileOverlay extends StatefulWidget {
  final OnRemoveOverlay onRemoveOverlay;

  const ProfileOverlay({super.key, required this.onRemoveOverlay});

  @override
  State<ProfileOverlay> createState() => _ProfileOverlayState();
}

class _ProfileOverlayState extends State<ProfileOverlay> {
  static const double _itemSpacer = 16;
  static const _artificialDelay = Duration(milliseconds: 500);
  final String _thirdPartyProviderHintEmail =
      (Database.providerId == 'password')
          ? ''
          : ' (specified by ${Database.providerId})';
  String? _email = Database.userEmail;
  String? _userName;
  String? _groupName = Database.groupName;
  int? _groupId = Database.groupId;

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

    _userName = Database.userName;
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
                        TextField(
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: 'Email$_thirdPartyProviderHintEmail',
                          ),
                          textInputAction: TextInputAction.done,
                          controller: TextEditingController(
                            text: _email,
                          ),
                          enabled: false,
                          onChanged: (value) => _email = value,
                        ),
                        const SizedBox(height: _itemSpacer),
                        GroupSelectionField(
                          groupId: _groupId,
                          groupName: _groupName,
                          clearHintOnConfirm: true,
                          enabled: !_groupIdChanging,
                          suffix: _groupIdChanging ? _textProgress : null,
                          suggestionBackgroundColor: Themes.grayLight,
                          onGroupNameChanged: (groupName, groupId) {
                            _groupName = groupName;
                            _groupId = groupId;
                          },
                          onSelectionConfirmed: (groupName, groupId) async {
                            _groupName = groupName;
                            _groupId = groupId;

                            if (Database.userId != null &&
                                Database.userName != null &&
                                _groupId != Database.groupId) {
                              setState(() {
                                _groupIdChanging = true;
                              });

                              await Shop.cancelUserGroupUpdates();

                              var group = await Group.switchGroup(
                                groupName,
                                groupId,
                                Database.userId!,
                                Database.userName!,
                              );
                              _groupId = group.groupId;

                              Shop.initializeUserGroupUpdates();

                              // clarify that an update is being applied
                              await Future.delayed(_artificialDelay);

                              setState(() {
                                _groupIdChanging = false;
                              });
                            }
                          },
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
                        /*
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
                          child: const Text(
                            'Pay with Paypal',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        */
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
                        onPressed: () async {
                          await Shop.cancelUserGroupUpdates();
                          await FirebaseAuth.instance.signOut();
                          widget.onRemoveOverlay();
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
      await Future.delayed(_artificialDelay);

      setState(() {
        _userNameChanging = false;
      });
    }
  }
}
