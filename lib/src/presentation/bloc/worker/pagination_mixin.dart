import 'dart:async';
import 'dart:math';

import 'package:api_bloc_base/src/presentation/bloc/base/independence_mixin.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import 'listener_bloc.dart';
import 'paginated_state.dart';

abstract class PaginatedInput<T> extends Equatable {
  final T input;
  final String? nextUrl;
  final int currentPage;

  const PaginatedInput(this.input, this.nextUrl, this.currentPage);

  @override
  get props => [this.input, this.nextUrl, this.currentPage];
}

class PaginatedOutput<T> extends Equatable {
  final Map<int, T> data;
  final bool isThereMore;
  final int currentPage;
  final String? nextPage;

  const PaginatedOutput(
      this.data, this.isThereMore, this.currentPage, this.nextPage);

  @override
  get props => [this.data, this.isThereMore, this.currentPage];
}

mixin PaginationMixin<Paginated extends PaginatedInput<Output>, Output>
    on
        ListenerBloc<Paginated, Output>,
        IndependenceMixin<Paginated, Output, WorkerState<Output>> {
  static const int startPage = 1;
  PaginatedOutput<Output> get empty =>
      const PaginatedOutput({}, false, startPage, null);

  Paginated? lastInput;

  int? _currentPage;

  int get currentPage => _currentPage ?? paginatedData.currentPage;
  int get lastPage => paginatedData.data.keys.fold(
      startPage, ((previousValue, element) => max(previousValue, element)));

  bool get canGoBack => currentPage > startPage;
  bool get canGoForward => currentPage < lastPage || isThereMore;
  bool get isThereMore => paginatedData.isThereMore;

  late PaginatedOutput<Output> paginatedData = empty;

  Stream<PaginatedOutput<Output>?> get paginatedStream =>
      stream.map((event) => paginatedData).distinct();

  @override
  @mustCallSuper
  void handleInputToInject(event) {
    final index = lastInput?.currentPage ?? 0;
    if (index < event.currentPage) {
      lastInput = event;
    }
    super.handleInputToInject(event);
  }

  @override
  @mustCallSuper
  handleInjectedInput(input) {
    final newData = input.input;
    final isThereMore = canGetMore(newData);
    final map = paginatedData.data;
    final newMap = Map.of(map);
    newMap[currentPage] = newData;
    paginatedData = PaginatedOutput(
      newMap,
      isThereMore,
      currentPage,
      lastInput?.nextUrl,
    );
  }

  @override
  convertInputToOutput(input) {
    return input.input;
  }

  bool canGetMore(Output newData) {
    if (lastInput != null && lastInput?.nextUrl == null) {
      return false;
    } else if (newData == null) {
      return false;
    } else if (newData is Iterable) {
      return newData.isNotEmpty;
    } else if (newData is Map) {
      return newData.isNotEmpty;
    } else {
      try {
        dynamic d = newData;
        return d.count > 0;
      } catch (e) {
        return false;
      }
    }
  }

  Future<void> next() async {
    if (canGoForward) {
      _currentPage = paginatedData.currentPage + 1;
      final nextData = paginatedData.data[_currentPage!];
      if (nextData != null) {
        emitData(nextData);
        emitCurrent();
      } else {
        fetchData(refresh: true);
      }
    }
  }

  Future<void> back() async {
    if (canGoBack) {
      _currentPage = paginatedData.currentPage - 1;
      final previousData = paginatedData.data[_currentPage!]!;
      emitData(previousData);
      emitCurrent();
    }
  }

  @override
  void clean() {
    super.clean();
    _currentPage = null;
    paginatedData = empty;
    lastInput = null;
  }

  @override
  void handleErrorState(errorState) {
    _currentPage = null;
    if (!hasData || safeData == null) {
      super.handleErrorState(errorState);
    } else {
      emit(ErrorGettingNextPageState<Output>(currentData, errorState.response));
    }
  }

  @override
  void handleLoadingState(loadingState) {
    if (!hasData || safeData == null) {
      super.handleLoadingState(loadingState);
    } else {
      emit(LoadingNextPageState<Output>(currentData));
    }
  }

  @override
  void emitLoaded(Output data) {
    emit(PaginatedLoadedState(paginatedData, data));
  }
}
