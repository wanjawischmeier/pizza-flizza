import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pizza_flizza/other/theme.dart';
import 'package:pizza_flizza/pages/login_page/widgets/group_selection_dialog.dart';
import 'package:pizza_flizza/widgets/group_selection_field.dart';

typedef OnGoogleSignInComplete = Future<void> Function(User user);

// based on: https://gist.github.com/sbis04/21e6ca27f2336a15cb6c5f704415ecd9
class GoogleSignInButton extends StatefulWidget {
  final OnGoogleSignInComplete? onGoogleSignInComplete;

  const GoogleSignInButton({
    super.key,
    this.onGoogleSignInComplete,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isSigningIn = false;
  int? _groupId;
  String _groupName = '';
  bool _groupSelected = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: OutlinedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.white),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ),
        onPressed: () async {
          setState(() {
            _isSigningIn = true;
          });

          // trigger the authentication flow
          final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

          // sign in process was aborted by user
          if (googleUser == null) {
            _isSigningIn = false;
            return;
          }

          // obtain the auth details from the request
          final GoogleSignInAuthentication googleAuth =
              await googleUser.authentication;

          // create a new credential
          final authCredential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          // once signed in, get the UserCredential
          var credential =
              await FirebaseAuth.instance.signInWithCredential(authCredential);

          User? user = credential.user;
          if (user == null) {
            await FirebaseAuth.instance.signOut();
          } else {
            await widget.onGoogleSignInComplete?.call(user);
          }

          setState(() {
            _isSigningIn = false;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            child: _isSigningIn
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Themes.cream),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset('assets/google_logo.png', height: 35),
                      const Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 20,
                            color: Themes.grayDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
