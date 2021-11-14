import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:equatable/equatable.dart';

abstract class BlocState extends Equatable {
  const BlocState();
  @override
  get props => [];
}

class Loading extends BlocState {
  const Loading();
}

class Loaded<T> extends BlocState {
  final T data;
  const Loaded(this.data);
  @override
  get props => [data];
}

class Error extends BlocState {
  final ResponseEntity response;
  const Error(this.response);
  @override
  get props => [response];
}
