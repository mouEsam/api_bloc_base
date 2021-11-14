import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:equatable/equatable.dart';

import '../base/state.dart';

abstract class ProviderState<T> extends Equatable implements BlocState {
  const ProviderState();

  @override
  bool get stringify => true;

  @override
  get props => [];
}

class ProviderLoading<T> extends ProviderState<T> implements Loading {}

class Invalidated<T> extends ProviderState<T> {}

class ProviderLoaded<T> extends ProviderState<T> implements Loaded<T> {
  final T data;

  const ProviderLoaded(this.data);

  @override
  get props => [this.data];
}

class ProviderError<T> extends ProviderState<T> implements Error {
  final ResponseEntity response;

  const ProviderError(this.response);

  @override
  get props => [this.response];
}
