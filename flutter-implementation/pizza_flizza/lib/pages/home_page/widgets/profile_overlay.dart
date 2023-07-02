import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/group.dart';
import 'package:pizza_flizza/database/shop.dart';
import 'package:pizza_flizza/other/theme.dart';
import 'package:pizza_flizza/widgets/group_selection_field.dart';
import 'package:url_launcher/url_launcher.dart';

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
      (Database.providerId == null || Database.providerId == 'password')
          ? ''
          : 'profile_overlay.email_specifier'.tr(args: [Database.providerId!]);
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
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'profile_overlay.header',
                    style: TextStyle(
                      fontSize: 24,
                      decoration: TextDecoration.none,
                    ),
                  ).tr(),
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
                            labelText: 'login.fields.username.title'.tr(),
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
                          labelText:
                              '${"login.fields.email.title".tr()}$_thirdPartyProviderHintEmail',
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
                          var userId = Database.userId;
                          var userName = Database.userName;
                          _groupName = groupName;
                          _groupId = groupId;

                          if (userId == null ||
                              userName == null ||
                              _groupId == Database.groupId) {
                            return;
                          }

                          setState(() {
                            _groupIdChanging = true;
                          });

                          await Shop.cancelUserGroupUpdates();

                          var group = await Group.switchGroup(
                            groupName,
                            groupId,
                            userId,
                            userName,
                          );

                          _groupId = group.groupId;
                          _groupName = group.groupName;
                          Database.groupId = _groupId;
                          Database.groupName = _groupName;

                          Shop.clearOrderData();
                          Shop.initializeUserGroupUpdates();

                          // clarify that an update is being applied
                          await Future.delayed(_artificialDelay);

                          setState(() {
                            _groupIdChanging = false;
                          });
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
                                    msg: 'login.actions.forgot_password.send'
                                        .tr(),
                                    toastLength: Toast.LENGTH_LONG,
                                  );
                                }).catchError(
                                  (error) {
                                    Fluttertoast.showToast(
                                      msg:
                                          'login.actions.forgot_password.failed'
                                              .tr(),
                                      toastLength: Toast.LENGTH_LONG,
                                    );
                                  },
                                );
                              },
                        child: const Text(
                          'login.actions.forgot_password.header',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ).tr(),
                      ),
                      TextButton(
                        onPressed: () => launchUrl(
                          Uri.parse(
                            'profile_overlay.account_management_url'.tr(),
                          ),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: const Text(
                          'profile_overlay.account_management',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ).tr(),
                      ),
                      TextButton(
                        onPressed: () => launchUrl(
                          Uri.parse(
                            'profile_overlay.report_bug_url'.tr(),
                          ),
                        ),
                        child: const Text(
                          'profile_overlay.report_bug',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ).tr(),
                      ),
                    ],
                  ),
                ),
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
                          'profile_overlay.log_out',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ).tr(),
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
                          'profile_overlay.close',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ).tr(),
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
      await Database.realtime
          .child('groups/${Database.groupId}/users/${Database.userId}')
          .set(_userName);
      // clarify that an update is being applied
      await Future.delayed(_artificialDelay);

      setState(() {
        _userNameChanging = false;
      });
    }
  }
}
