import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pizza_flizza/other/theme.dart';
import 'package:pizza_flizza/pages/intro_page/intro_page.dart';
import 'package:url_launcher/url_launcher.dart';

// thanks to: https://stackoverflow.com/a/62341566/13215204
class UnorderedListItem extends StatelessWidget {
  final List<InlineSpan>? lines;
  final double lineFontSize;

  const UnorderedListItem(
    this.lines, {
    super.key,
    this.lineFontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "• ",
            style: TextStyle(fontSize: lineFontSize),
          ),
          Expanded(
            child: RichText(
                text: TextSpan(
              style: TextStyle(fontSize: lineFontSize),
              children: lines,
            )),
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicySlide extends StatefulWidget {
  final OnContinue? onContinue;

  const PrivacyPolicySlide({super.key, this.onContinue});

  @override
  State<PrivacyPolicySlide> createState() => _PrivacyPolicySlideState();
}

class _PrivacyPolicySlideState extends State<PrivacyPolicySlide> {
  final _privacyPolicyUri = Uri.parse(
    'https://wanjawischmeier.github.io/pizza-flizza/pages/privacy-policy/de',
  );

  bool _policyChecked = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Image.asset(
          'assets/privacy_policy.png',
          color: Themes.grayLight,
          scale: 4,
        ),
        const Text(
          'About Your Data...',
          style: TextStyle(fontSize: 20),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.only(left: 16),
          alignment: Alignment.centerLeft,
          child: const Text(
            'PizzaFlizza erfasst und speichert:',
            style: TextStyle(fontSize: 14),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            children: [
              UnorderedListItem([
                TextSpan(text: 'Den von dir festgelegten '),
                TextSpan(
                  text: 'Benutzernamen',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ]),
              UnorderedListItem([
                TextSpan(text: 'Die dem Konto zugehörige '),
                TextSpan(
                  text: 'Email',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ]),
              UnorderedListItem([
                TextSpan(text: 'Deine '),
                TextSpan(
                  text: 'Bestellungen',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ]),
              UnorderedListItem([
                TextSpan(text: 'Für andere Benutzer*innen '),
                TextSpan(
                  text: 'erfüllte Bestellungen',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ]),
              UnorderedListItem([
                TextSpan(text: 'Einen '),
                TextSpan(
                  text: 'Verlauf',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      ' an in der Vergangenheit liegenden eigenen Bestellungen',
                ),
              ]),
              UnorderedListItem([
                TextSpan(text: 'Eine '),
                TextSpan(
                  text: 'anonyme Statistik',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' zur Anzahl an Käufen pro Artikel'),
              ]),
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Checkbox(
              value: _policyChecked,
              onChanged: (value) {
                setState(() {
                  _policyChecked = value ?? false;
                });

                if (_policyChecked) {
                  Future.delayed(
                    const Duration(milliseconds: 500),
                    widget.onContinue,
                  );
                }
              },
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14),
                  children: [
                    TextSpan(
                      text:
                          'I consent to Google having full insights into my ever-escalating pizza consumption.\n(I aggree to the ',
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          setState(() {
                            _policyChecked = !_policyChecked;
                          });

                          if (_policyChecked) {
                            Future.delayed(
                              const Duration(milliseconds: 500),
                              widget.onContinue,
                            );
                          }
                        },
                    ),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        color: Colors.lightBlue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          launchUrl(_privacyPolicyUri);
                        },
                    ),
                    const TextSpan(text: ')'),
                  ],
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 25),
          child: RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 10),
              children: [
                TextSpan(text: 'Der Verlauf '),
                TextSpan(
                  text: 'kann jederzeit in der App gelöscht',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      ' werden und wird damit einhergehend auch unverzüglich aus der Cloud entfernt. Die App erhebt ',
                ),
                TextSpan(
                  text: 'keinerlei standortbezogene Daten',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' und verwendet auch '),
                TextSpan(
                  text: 'keinerlei Analyse-Tools',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      ' zum Auswerten von In-App- oder Kaufverhalten. Es werden ',
                ),
                TextSpan(
                  text: 'keine Diagnosedaten oder Absturzberichte',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      ' gesendet. Das Löschen entweder des gesamten Kontos oder lediglich aller mit dem Profil assoziierten Daten ist unter der in der Datenschutzerklärung genannten Adresse möglich.',
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 2),
          child: Text(
            'Privacy policy icon created by Anggara - Flaticon',
            style: TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
