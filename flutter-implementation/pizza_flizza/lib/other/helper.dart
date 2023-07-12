import 'package:intl/intl.dart';

class Helper {
  static String formatPrice(double price) {
    return NumberFormat.simpleCurrency(
      locale: 'de_DE', // Localizations.localeOf(context).scriptCode,
    ).format(price);
  }

  static Map<int, T> sortByHighestKey<T>(Map<int, T> map) {
    return Map.fromEntries(
        map.entries.toList()..sort((e1, e2) => e2.key.compareTo(e1.key)));
  }

  static Map<T, int> sortByHighestValue<T>(Map<T, int> map) {
    return Map.fromEntries(
        map.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value)));
  }

  static Map<K, V> sortByComparator<K, V>(
    Map<K, V> map,
    int Function(MapEntry<K, V>, MapEntry<K, V>) comparator,
  ) {
    return Map.fromEntries(map.entries.toList()..sort(comparator));
  }
}
