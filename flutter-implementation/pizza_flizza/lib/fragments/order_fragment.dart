import 'package:cached_firestorage/remote_picture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:pizza_flizza/database.dart';
import 'package:pizza_flizza/theme.dart';
import 'package:pizza_flizza/widgets/order_card.dart';
import 'package:firebase_storage/firebase_storage.dart';

class OrderFragment extends StatefulWidget {
  const OrderFragment({super.key});

  @override
  State<OrderFragment> createState() => _OrderFragmentState();
}

class _OrderFragmentState extends State<OrderFragment> {
  Map<String, List<OrderCardWidget>> map = {};
  static const String _basePath = 'shops/penny_burgtor/items';

  @override
  void initState() {
    super.initState();
    Shop.onChanged = () => setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: List.generate(Shop.items.length, (index) {
        var category = Shop.items.entries.elementAt(index);
        var categoryName = category.value['0_name'];
        var categoryItems = Map.from(category.value);
        categoryItems.remove('0_name');

        return SliverStickyHeader(
          overlapsContent: false,
          header: Container(
            color: Themes.grayDark.withOpacity(0.9),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Flexible(
                  fit: FlexFit.tight,
                  child: Divider(
                    color: Themes.grayMid,
                    thickness: 2,
                  ),
                ),
              ],
            ),
          ),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            childAspectRatio: 1,
            children: List.generate(categoryItems.length, (itemIndex) {
              var item = categoryItems.entries.elementAt(itemIndex);
              String name = item.value['name'];
              double price = item.value['price'];

              return Padding(
                padding: const EdgeInsets.all(4),
                child: OrderCardWidget(
                  name: name,
                  price: price,
                  image: _getCachedImage(item.key),
                  onCountChanged: (count) {
                    return true;
                  },
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  RemotePicture? _getCachedImage(String itemId) {
    var path = Shop.getItemImageReference(itemId);

    if (path == null) {
      return null;
    } else {
      return RemotePicture(imagePath: path, mapKey: itemId);
    }
  }
}
