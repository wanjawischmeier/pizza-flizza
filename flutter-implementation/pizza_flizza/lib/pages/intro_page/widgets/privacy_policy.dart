import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pizza_flizza/widgets/circular_avatar_icon.dart';
import 'package:url_launcher/url_launcher.dart';

typedef OnContinue = void Function();

// thanks to: https://stackoverflow.com/a/62341566/13215204
class UnorderedListItem extends StatelessWidget {
  final String textKey;
  final List<String> highlighted;
  final bool bulletPoint;
  final double lineFontSize;
  final TextStyle boldStyle = const TextStyle(fontWeight: FontWeight.bold);

  const UnorderedListItem(
    this.highlighted,
    this.textKey, {
    super.key,
    this.bulletPoint = true,
    this.lineFontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    var text = textKey.tr();
    // split text at all highlighted words
    var segments = text
        .splitMapJoin(
          RegExp('(${highlighted.join("|")})'),
          onMatch: (Match match) {
            return '#${match.group(0)}#'; // Include the delimiter in the result
          },
          onNonMatch: (String nonMatch) {
            return nonMatch;
          },
        )
        .split('#')
        .where((segment) => segment.isNotEmpty);

    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: bulletPoint ? 4 : 0, horizontal: bulletPoint ? 8 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            child: bulletPoint
                ? Text(
                    "• ",
                    style: TextStyle(fontSize: lineFontSize),
                  )
                : null,
          ),
          Expanded(
            child: RichText(
                text: TextSpan(
              style: TextStyle(fontSize: lineFontSize),
              children: [
                for (String segment in segments) ...[
                  TextSpan(
                    text: segment,
                    style: highlighted.contains(segment) ? boldStyle : null,
                  ),
                ],
              ],
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
  static const String _disclaimerPath = 'intro.privacy_policy.disclaimer';
  final List<String> _disclaimerHighlighted =
      '$_disclaimerPath.highlighted'.tr().split(';');
  final List<String> _infoHighlighted =
      'intro.privacy_policy.info_highlighted'.tr().split(';');
  final _privacyPolicyUri = Uri.parse(
    'intro.privacy_policy.policy_url'.tr(),
  );

  bool _policyChecked = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        const Padding(
          padding: EdgeInsets.all(8),
          child: CircularAvatarIcon(
            padding: EdgeInsets.all(20),
            iconData: Icons.privacy_tip_outlined,
          ),
        ),
        const Text(
          'intro.privacy_policy.title',
          style: TextStyle(fontSize: 22),
        ).tr(),
        const Spacer(),
        Container(
          padding: const EdgeInsets.only(left: 16),
          alignment: Alignment.centerLeft,
          child: const Text(
            'intro.privacy_policy.disclaimer.header',
            style: TextStyle(fontSize: 14),
          ).tr(),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              UnorderedListItem(
                _disclaimerHighlighted,
                '$_disclaimerPath.username',
              ),
              UnorderedListItem(
                _disclaimerHighlighted,
                '$_disclaimerPath.email',
              ),
              UnorderedListItem(
                _disclaimerHighlighted,
                '$_disclaimerPath.your_orders',
              ),
              UnorderedListItem(
                _disclaimerHighlighted,
                '$_disclaimerPath.other_orders',
              ),
              UnorderedListItem(
                _disclaimerHighlighted,
                '$_disclaimerPath.history',
              ),
              UnorderedListItem(
                _disclaimerHighlighted,
                '$_disclaimerPath.stats',
              ),
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: UnorderedListItem(
            _infoHighlighted,
            'intro.privacy_policy.info',
            bulletPoint: false,
            lineFontSize: 10,
          ),
        ),
        Row(
          children: [
            Checkbox(
              value: _policyChecked,
              onChanged: (value) {
                setState(() {
                  _policyChecked = value ?? false;
                });

                if (_policyChecked) {
                  widget.onContinue?.call();
                }
              },
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14),
                  children: [
                    TextSpan(
                      text: 'intro.privacy_policy.consent_info'.tr(),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          setState(() {
                            _policyChecked = !_policyChecked;
                          });

                          if (_policyChecked) {
                            widget.onContinue?.call();
                          }
                        },
                    ),
                    TextSpan(
                      text: 'intro.privacy_policy.consent_link'.tr(),
                      style: const TextStyle(
                        color: Colors.lightBlue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          launchUrl(_privacyPolicyUri);
                        },
                    ),
                    TextSpan(text: 'intro.privacy_policy.consent_end'.tr()),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 50),
      ],
    );
  }
}
