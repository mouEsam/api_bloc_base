import 'dart:async';
import 'dart:math';

import 'package:api_bloc_base/src/presentation/bloc/base/independence_mixin.dart';
import 'package:equatable/equatable.dart';

import 'listener_bloc.dart';
import 'paginated_state.dart';

abstract class Paginated<T> {
  T get item;
}

class SimplePaginated<T> extends Equatable implements Paginated<T> {
  @override
  final T item;

  const SimplePaginated(this.item);

  @override
  List<Object?> get props => [item];
}

abstract class PaginatedInput<T> extends Equatable {
  final T input;
  final String? nextUrl;
  final int currentPage;

  const PaginatedInput(this.input, this.nextUrl, this.currentPage);

  @override
  List<Object?> get props => [input, nextUrl, currentPage];
}

class PaginatedOutput<T> extends Equatable {
  final Map<int, T> dataMap;
  final Paginated<T> _data;
  final bool isThereMore;
  final int currentPage;
  final int? lastPage;

  T get page => _data.item;

  const PaginatedOutput(
    this.dataMap,
    this._data,
    this.isThereMore,
    this.currentPage,
    this.lastPage,
  );

  PaginatedOutput<T> mapData(Paginated<T> Function(Paginated<T> data) mapper) {
    return PaginatedOutput(
      dataMap,
      mapper(_data),
      isThereMore,
      currentPage,
      lastPage,
    );
  }

  @override
  List<Object?> get props => [
        dataMap,
        _data,
        isThereMore,
        currentPage,
        lastPage,
      ];
}

mixin PaginationMixin<Input extends PaginatedInput<Output>, Output>
    on
        ListenerBloc<Input, PaginatedOutput<Output>>,
        IndependenceMixin<Input, PaginatedOutput<Output>,
            WorkerState<PaginatedOutput<Output>>> {
  int get startPage => 1;

  int get invalidPage => startPage - 1;

  int get currentPage => safeData?.currentPage ?? invalidPage;

  int get lastPage => safeData?.lastPage ?? currentPage;

  late int? _wantedPage = startPage;

  int get nextPage => _wantedPage ?? startPage;

  bool get canGoBack => currentPage > startPage;

  bool get canGoForward => currentPage < lastPage || isThereMore;

  bool get isThereMore => safeData?.isThereMore != false;

  @override
  PaginatedOutput<Output> convertInputToOutput(Input input) {
    return _createOutput(input.input, input.currentPage, input.nextUrl);
  }

  PaginatedOutput<Output> _createOutput(
    Output data,
    int page, [
    String? nextPage,
  ]) {
    final Map<int, Output> initialDataMap = safeData?.dataMap ?? {};
    final bool initialIsThereMore = safeData?.isThereMore ?? true;
    final int initialCurrentPage = safeData?.currentPage ?? invalidPage;
    final int initialLastPage = safeData?.lastPage ?? invalidPage;

    final newMap = Map.of(initialDataMap);
    newMap[page] = data;
    final newLast = newMap.keys.reduce((value, element) => max(value, element));
    final bool isThereMore;
    if (page != initialLastPage && page == newLast) {
      isThereMore = nextPage != null;
    } else {
      isThereMore = initialIsThereMore;
    }

    final newData = createOutput(newMap, page);
    final newOutput = createPaginatedOutput(
      newMap,
      newData,
      isThereMore,
      page,
      newLast,
    );
    return _fixForPage(newOutput, _wantedPage ??= page);
  }

  PaginatedOutput<Output> _fixForPage(
    PaginatedOutput<Output> startData,
    int page,
  ) {
    final newData = createOutput(startData.dataMap, page);
    return createPaginatedOutput(
      startData.dataMap,
      newData,
      startData.isThereMore,
      page,
      startData.lastPage,
    );
  }

  PaginatedOutput<Output> createEmptyOutput(Output obj) {
    return createPaginatedOutput(
      {},
      createOutput({invalidPage: obj}, invalidPage),
      false,
      invalidPage,
      invalidPage,
    );
  }

  void emitEmptyOutput(Output obj) {
    currentData = createEmptyOutput(obj);
  }

  Paginated<Output> createOutput(Map<int, Output> dataMap, int page) {
    return SimplePaginated(dataMap[page]!);
  }

  PaginatedOutput<Output> createPaginatedOutput(
    Map<int, Output> dataMap,
    Paginated<Output> data,
    bool isThereMore,
    int currentPage,
    int? lastPage,
  ) {
    return PaginatedOutput(
      dataMap,
      data,
      isThereMore,
      currentPage,
      lastPage,
    );
  }

  Future<void> next() async {
    if (canGoForward) {
      final page = currentPage + 1;
      getPage(page);
    }
  }

  Future<void> back() async {
    if (canGoBack) {
      final page = currentPage - 1;
      getPage(page);
    }
  }

  void getPage(int page) {
    _wantedPage = page;
    final previousData = safeData?.dataMap[nextPage];
    if (safeData != null && previousData != null) {
      injectOutput(_createOutput(previousData, nextPage));
      emitCurrent();
    } else {
      fetchData();
    }
  }

  @override
  void clean() {
    super.clean();
    _wantedPage = null;
  }

  @override
  void handleErrorState(errorState) {
    if (!hasData || safeData is! PaginatedOutput<Output>) {
      super.handleErrorState(errorState);
    } else {
      emit(
        ErrorGettingNextPageState<PaginatedOutput<Output>>(
          currentData,
          errorState.response,
        ),
      );
    }
  }

  @override
  void handleLoadingState(loadingState) {
    if (!hasData || safeData is! PaginatedOutput<Output>) {
      super.handleLoadingState(loadingState);
    } else {
      emit(LoadingNextPageState<PaginatedOutput<Output>>(currentData));
    }
  }
}
