import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/worker/listener_bloc.dart';
import 'package:rxdart/rxdart.dart';

import '../base/state.dart';

abstract class FilterType {}

mixin ListingMixin<Input, Output, Filtering extends FilterType>
    on ListenerBloc<Input, Output> {
  int get searchDelayMillis;

  get outputStream =>
      CombineLatestStream.combine3<BlocState, Filtering?, String, BlocState>(
              super.outputStream, filterStream, queryStream, (a, b, c) => a)
          .asBroadcastStream(onCancel: (sub) => sub.cancel());

  @override
  get subjects => super.subjects..addAll([_filterSubject, _querySubject]);

  Output convertInjectedOutput(Output output) =>
      applyFilter(output, filter, query);

  Output applyFilter(Output output, Filtering? filter, String query) {
    return output;
  }

  final _filterSubject = BehaviorSubject<Filtering?>()..value = null;

  Stream<Filtering?> get filterStream => _filterSubject.shareValue();

  Filtering? get filter => _filterSubject.valueOrNull;

  set filter(Filtering? filter) {
    _filterSubject.add(filter);
  }

  final _querySubject = BehaviorSubject<String>()..value = '';

  Stream<String> get queryStream => _querySubject
      .shareValue()
      .debounceTime(Duration(milliseconds: searchDelayMillis));

  String get query => _querySubject.value;

  set query(String query) {
    _querySubject.add(query);
  }
}
