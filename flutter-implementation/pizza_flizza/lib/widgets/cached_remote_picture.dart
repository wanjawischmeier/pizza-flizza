import 'package:cached_firestorage/lib.dart';
import 'package:flutter/material.dart';
import 'package:pizza_flizza/database.dart';
import 'package:pizza_flizza/theme.dart';

class RemoteItemImage extends StatelessWidget {
  final String itemId;

  const RemoteItemImage({
    Key? key,
    required this.itemId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var path = Shop.getItemImageReference(itemId);

    if (path == null) {
      return const FittedBox(
        fit: BoxFit.fill,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.image_not_supported, color: Themes.grayLight),
        ),
      );
    } else {
      return RemotePicture(imagePath: path, mapKey: path);
    }
  }
}
