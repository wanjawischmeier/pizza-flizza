class Database {
  static late Database instance;
  static void initialize() {
    instance = Database();
  }

  late Shop shop;

  Database() {
    shop = Shop();
  }
}

class Shop {}

class User {
  String email;
  String creationDate;

  User(
    this.email,
    this.creationDate,
  );
}
