import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

typedef OnShopChanged = void Function();

class Database {
  static var storage = FirebaseStorage.instance.ref();
  static var realtime = FirebaseDatabase.instance.ref();
}

class Shop {
  static late String _shopId;
  static OnShopChanged? onChanged;
  static Map<dynamic, dynamic> shops = {};
  static Map<dynamic, dynamic> get items {
    return shops[shopId]['items'];
  }

  static final Map<String, List<Reference>> _itemReferences = {};

  static String get shopId => _shopId;
  static set shopId(String newShopId) {
    _shopId = newShopId;
    onChanged?.call();
  }

  static Future<void> loadAll() async {
    var snapshot = await Database.realtime.child('shops').get();
    shops = snapshot.value as Map<dynamic, dynamic>;
    shopId = shops.keys.first;

    for (String shop in shops.keys) {
      var snapshot =
          await Database.storage.child('shops/$shop/items').listAll();
      _itemReferences[shop] = snapshot.items;
    }

    shopId;
  }

  static String? getItemImageReference(String itemId) {
    String path = 'shops/$_shopId/items/$itemId.png';
    var reference = Database.storage.child(path);
    if (_itemReferences[_shopId]?.contains(reference) ?? false) {
      return path;
    } else {
      return null;
    }
  }
}
