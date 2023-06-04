import 'package:cached_firestorage/lib.dart';
import 'package:flutter/material.dart';

import 'package:pizza_flizza/database/shop.dart';
import 'package:pizza_flizza/theme.dart';

class RemoteItemImage extends StatelessWidget {
  final String itemId;

  const RemoteItemImage({
    super.key,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context) {
    String path = 'shops/${Shop.currentShopId}/items/$itemId.png';
    if (Shop.containsReference(path)) {
      return RemotePicture(imagePath: path, mapKey: path);
    } else {
      return const FittedBox(
        fit: BoxFit.fill,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.image_not_supported, color: Themes.grayLight),
        ),
      );
    }
  }
}
