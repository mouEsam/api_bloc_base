import 'package:api_bloc_base/src/domain/entity/locked_list.dart';

import 'pagination_mixin.dart';

mixin PaginationListMixin<Input extends PaginatedInput<PaginationList<Output>>,
    Output> on PaginationMixin<Input, PaginationList<Output>> {
  // @override
  // PaginatedOutput<PageList<Output>> get empty =>
  //     const PaginatedOutput({}, false, PaginationMixin.startPage, null);
  //
  // @override
  // PaginatedOutput<PageList<Output>> get paginatedData =>
  //     super.paginatedData as PaginatedOutput<PageList<Output>>;

  @override
  createOutput(map, page) {
    if (map.length == 1) {
      return PageList(map.values.first);
    } else {
      final PagesList<Output> newList = PagesList.empty();
      final sortedIndices = map.keys.toList();
      sortedIndices.sort();
      for (final index in sortedIndices) {
        newList.addPage(PageList(map[index]));
      }
      return newList;
    }
  }

  @override
  convertOutputToInject(output) {
    return output.mapData(
        (data) => data is PaginationList<Output> ? data.asSinglePage : data);
  }
}
