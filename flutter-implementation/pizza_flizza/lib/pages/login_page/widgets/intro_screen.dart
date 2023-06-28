import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:pizza_flizza/other/logger.util.dart';

// thanks to: https://stackoverflow.com/a/62341566/13215204
class UnorderedListItem extends StatelessWidget {
  const UnorderedListItem(this.lines, {super.key});
  final List<InlineSpan>? lines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          "• ",
          style: TextStyle(fontSize: 22),
        ),
        Expanded(
          child: RichText(
              text: TextSpan(
            style: const TextStyle(fontSize: 22),
            children: lines,
          )),
        ),
      ],
    );
  }
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  static final log = AppLogger();
  List<ContentConfig> listContentConfig = [];

  @override
  void initState() {
    super.initState();

    listContentConfig.add(
      const ContentConfig(
        title: "ERASER",
        description:
            "Allow miles wound place the leave had. To sitting subject no improve studied limited",
        pathImage: "images/photo_eraser.png",
        backgroundColor: Color(0xfff5a623),
      ),
    );
    listContentConfig.add(
      const ContentConfig(
        title: "Privacy Policy",
        widgetDescription: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('center'),
            Text('bottom'),
          ],
        ),
        pathImage: "images/photo_ruler.png",
        backgroundColor: Color(0xff9932CC),
      ),
    );
  }

  void onDonePress() {
    log.d("End of slides");
  }

  @override
  Widget build(BuildContext context) {
    return IntroSlider(
      key: UniqueKey(),
      listContentConfig: listContentConfig,
      onDonePress: onDonePress,
    );
  }
}
