import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Logical screen IDs stay stable even when permissions hide destinations.
class AppTab {
  static const dashboard = 0,
      customers = 1,
      archive = 2,
      orders = 3,
      debts = 4,
      workshopDebts = 5,
      workers = 6,
      expenses = 7,
      inventory = 8,
      reports = 9,
      activity = 10,
      settings = 11;
}

final selectedTabProvider = StateProvider<int>((ref) => AppTab.dashboard);
