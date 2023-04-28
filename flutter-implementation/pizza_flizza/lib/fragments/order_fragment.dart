import 'package:cached_firestorage/remote_picture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:pizza_flizza/theme.dart';
import 'package:pizza_flizza/widgets/order_card.dart';
import 'package:firebase_storage/firebase_storage.dart';

class OrderFragment extends StatefulWidget {
  const OrderFragment({super.key});

  @override
  State<OrderFragment> createState() => _OrderFragmentState();
}

class _OrderFragmentState extends State<OrderFragment> {
  static const Map<String, Map<String, double>> items =
      <String, Map<String, double>>{
    'hearty': {
      'pizza': 1.2,
      'baguette': 2.9,
      'bread_party': 2.9,
      'bread_ciabatta': 2.9,
      'baguette_oven': 2.9,
      'rod_chicken': 2.9,
      'roll_sunday': 2.9,
    },
    'sweet': {
      'apple_triangle': 10.3,
      'donut_whole_milk': 2.9,
      'humus_natural': 2.9,
      'berliner_vanilla': 2.9,
      'berliner': 2.9,
      'croissant': 2.9,
    },
    'dips': {
      'baguette': 2.9,
      'bread_party': 2.9,
      'bread_ciabatta': 2.9,
      'humus_natural': 2.9,
      'berliner_vanilla': 2.9,
      'berliner': 2.9,
    },
  };

  Map<String, List<OrderCardWidget>> map = {};
  static const String _basePath = '/items/penny_burgtor';
  final Reference _storage = FirebaseStorage.instance.ref();
  List<Reference>? _itemReferences;

  @override
  void initState() {
    super.initState();
    _storage.child(_basePath).listAll().then((list) {
      _itemReferences = list.items;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: List.generate(items.length, (index) {
        var category = items.entries.elementAt(index);

        return SliverStickyHeader(
          overlapsContent: false,
          header: Container(
            color: Themes.grayDark.withOpacity(0.9),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(category.key),
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
            children: List.generate(category.value.length, (itemIndex) {
              var item = category.value.entries.elementAt(itemIndex);

              return Padding(
                padding: const EdgeInsets.all(8),
                child: OrderCardWidget(
                  itemId: item.key,
                  price: item.value,
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

  RemotePicture? _getCachedImage(String imageName) {
    var path = '$_basePath/$imageName.png';

    if (_itemReferences?.contains(_storage.child(path)) ?? false) {
      return RemotePicture(imagePath: path, mapKey: imageName);
    } else {
      return null;
    }
  }
}
