import 'package:logger/logger.dart';
import 'package:pizza_flizza/database/item.dart';

class AppLogger extends Logger {
  AppLogger()
      : super(
          printer: PrettyPrinter(
            lineLength: 90,
            colors: true,
            printEmojis: false,
            methodCount: 1,
            errorMethodCount: 5,
          ),
        );

  void logOrderItems(Map<String, OrderItem> items, String userId, String shopId,
      String? fulfillerId) {
    String fulfiller =
        (fulfillerId == null) ? '' : 'fulfilled by $fulfillerId ';
    String fulfilledString =
        'parsed order from $userId ${fulfiller}at $shopId:\n';
    items.forEach((itemId, item) {
      fulfilledString += '$itemId: ${item.count}\n';
    });
    i(fulfilledString.substring(0, fulfilledString.length - 1));
  }

  void logHistoryOrderItems(
      Map<String, int> items, String userId, String shopId) {
    String fulfilledString = 'parsed history from $userId at $shopId:\n';
    items.forEach((itemId, count) {
      fulfilledString += '$itemId: $count\n';
    });
    i(fulfilledString.substring(0, fulfilledString.length - 1));
  }
}
