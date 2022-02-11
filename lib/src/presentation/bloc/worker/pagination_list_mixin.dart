import 'package:api_bloc_base/src/domain/entity/locked_list.dart';
import 'package:flutter/foundation.dart';

import 'pagination_mixin.dart';

mixin PaginationListMixin<Paginated extends PaginatedInput<PageList<Output>>,
    Output> on PaginationMixin<Paginated, PaginationList<Output>> {
  // @override
  // PaginatedOutput<PageList<Output>> get empty =>
  //     const PaginatedOutput({}, false, PaginationMixin.startPage, null);
  //
  // @override
  // PaginatedOutput<PageList<Output>> get paginatedData =>
  //     super.paginatedData as PaginatedOutput<PageList<Output>>;

  @override
  @mustCallSuper
  convertInputToOutput(input) {
    final map = paginatedData.data;
    if (map.length == 1) {
      return PageList(map.values.first);
    } else {
      final PagesList<Output> newList = PagesList.empty();
      final sortedIndices = map.keys.toList();
      sortedIndices.sort();
      for (final index in sortedIndices) {
        newList.addPage(map[index]!);
      }
      return newList;
    }
  }

  @override
  convertOutputToInject(output) {
    return output.asSinglePage;
  }
}
