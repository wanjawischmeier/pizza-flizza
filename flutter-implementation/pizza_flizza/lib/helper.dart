import 'package:intl/intl.dart';

class Helper {
  static String formatPrice(double price) {
    return NumberFormat.simpleCurrency(
      locale: 'de_DE', // Localizations.localeOf(context).scriptCode,
    ).format(price);
  }
}
