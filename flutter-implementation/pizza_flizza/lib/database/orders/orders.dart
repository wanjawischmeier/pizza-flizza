import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import 'order.dart';

class Orders {
  static final OrderMap orders = {};
  static final FulfilledMap fulfilled = {};
  static final HistoryMap history = {};

  static final StreamController<void> ordersPushedController =
      StreamController.broadcast();
  static StreamSubscription subscribeToOrdersPushed(
      void Function(void) onUpdate) {
    return ordersPushedController.stream.listen(onUpdate);
  }

  static final StreamController<OrderMap> ordersUpdatedController =
      StreamController.broadcast();
  static StreamSubscription<OrderMap> subscribeToOrdersUpdated(
      void Function(OrderMap orders) onUpdate) {
    onUpdate(orders);
    return ordersUpdatedController.stream.listen(onUpdate);
  }

  static final StreamController<FulfilledMap> fulfilledUpdatedController =
      StreamController.broadcast();
  static StreamSubscription<FulfilledMap> subscribeToFulfilledUpdated(
      void Function(FulfilledMap orders) onUpdate) {
    onUpdate(fulfilled);
    return fulfilledUpdatedController.stream.listen(onUpdate);
  }

  static final StreamController<HistoryMap> historyUpdatedController =
      StreamController.broadcast();
  static StreamSubscription<HistoryMap> subscribeToHistoryUpdated(
      void Function(HistoryMap orders) onUpdate) {
    onUpdate(history);
    return historyUpdatedController.stream.listen(onUpdate);
  }

  static StreamSubscription<DatabaseEvent>? groupDataAddedSubscription,
      groupDataChangedSubscription,
      groupDataRemovedSubscription;
}
