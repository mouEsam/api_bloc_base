import 'package:flutter/foundation.dart';

import 'pagination_mixin.dart';

mixin PaginationListMixin<Paginated extends PaginatedInput<List<Output>>,
    Output> on PaginationMixin<Paginated, List<Output>> {
  @override
  @mustCallSuper
  convertInputToOutput(input) {
    final map = paginatedData.data;
    final List<Output> newList = [];
    final sortedIndices = map.keys.toList();
    sortedIndices.sort();
    for (final index in sortedIndices) {
      newList.addAll(map[index]!);
    }
    return newList;
  }
}
