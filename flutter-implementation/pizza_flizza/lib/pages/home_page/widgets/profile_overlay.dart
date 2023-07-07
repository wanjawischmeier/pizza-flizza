import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:pizza_flizza/database/database.dart';
import 'package:pizza_flizza/database/group.dart';
import 'package:pizza_flizza/database/orders/order_manager.dart';
import 'package:pizza_flizza/database/orders/order_parser.dart';
import 'package:pizza_flizza/database/orders/orders.dart';
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
      (Database.currentUser?.providerId == null ||
              Database.currentUser?.providerId == 'password')
          ? ''
          : 'profile_overlay.email_specifier'.tr(
              args: [Database.currentUser!.providerId!],
            );

  String? _email, _userName, _groupName;
  int? _groupId;
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

    _email = Database.currentUser?.userEmail;
    _userName = Database.currentUser?.userName;
    _groupName = Database.currentUser?.group.groupName;
    _groupId = Database.currentUser?.group.groupId;
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
                          _groupName = groupName;
                          _groupId = groupId;

                          var user = Database.currentUser;
                          if (user == null) {
                            return;
                          }

                          setState(() {
                            _groupIdChanging = true;
                          });

                          await OrderParser.cancelUserGroupUpdates();

                          var group = await Group.switchGroup(
                            groupName,
                            groupId,
                            user.userId,
                            user.userName,
                          );

                          _groupId = group.groupId;
                          _groupName = group.groupName;
                          if (_groupId != null) {
                            user.group.groupId = _groupId!;
                          }
                          if (_groupName != null) {
                            user.group.groupName = _groupName!;
                          }

                          OrderManager.clearOrderData();
                          OrderParser.initializeUserGroupUpdates();

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
                      Row(
                        children: [
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
                            onPressed: () async {
                              Orders.userStats?.clear();
                              await Database.userReference
                                  ?.child('stats')
                                  .remove();

                              Shop.sortShopItems(Shop.currentShopId);
                              Shop.shopChangedController
                                  .add(Shop.currentShopId);

                              Fluttertoast.showToast(
                                msg: 'profile_overlay.clear_stats_success'.tr(),
                                toastLength: Toast.LENGTH_LONG,
                              );
                            },
                            child: const Text(
                              'profile_overlay.clear_stats',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ).tr(),
                          ),
                        ],
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
                          await OrderParser.cancelUserGroupUpdates();
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
    var user = Database.currentUser;
    if (!hasFocus &&
        (_userName?.isNotEmpty ?? false) &&
        user != null &&
        _userName != user.userName) {
      setState(() {
        _userNameChanging = true;
      });

      Database.currentUser?.userName = _userName!;
      await Database.realtime
          .child('groups/${user.group.groupId}/users/${user.userId}')
          .set(_userName);
      // clarify that an update is being applied
      await Future.delayed(_artificialDelay);

      setState(() {
        _userNameChanging = false;
      });
    }
  }
}
