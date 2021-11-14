import 'pagination_mixin.dart';

mixin PaginationListMixin<Paginated extends PaginatedInput<List<Output>>,
    Output> on PaginationMixin<Paginated, List<Output>> {
  @override
  convertOutputToInject(data) {
    final isThereMore = canGetMore(data);
    final map = paginatedData.data;
    final newMap = Map.of(map);
    newMap[currentPage] = data;
    paginatedData =
        PaginatedOutput(newMap, isThereMore, currentPage, lastInput?.nextUrl);
    final List<Output> newList = [];
    final sortedIndices = newMap.keys.toList();
    sortedIndices.sort();
    for (final index in sortedIndices) {
      newList.addAll(newMap[index]!);
    }
    return newList;
  }
}
