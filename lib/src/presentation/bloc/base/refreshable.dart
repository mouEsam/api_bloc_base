import 'dart:async';

abstract class Refreshable {
  FutureOr<void> refreshData();
  FutureOr<void> refetchData();
}
