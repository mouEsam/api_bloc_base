import 'dart:async';

import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:flutter/material.dart';

class OperationData {
  final String loadingMessage;
  final Stream<double>? progress;
  final VoidCallback? onCancel;

  const OperationData(
      {required this.loadingMessage, this.progress, this.onCancel});
}

typedef StateErrorBuilder<E extends Error> = Widget Function(
    BuildContext context, E error, Widget? loaded);
typedef StateLoadingBuilder<L extends Loading> = Widget Function(
    BuildContext context, L loading, Widget? loaded);
typedef StateOnGoingOperationBuilder<Data> = Widget Function(
    BuildContext context,
    OnGoingOperationState<Data> operation,
    Widget? loaded);
typedef StateBuilder<T> = Widget Function(
    BuildContext context, T data, BaseErrors? errors);
typedef StateListener<S> = FutureOr<bool> Function(
    BuildContext context, S state);

typedef BlocErrorBuilder<Bloc, E extends Error> = Widget Function(
    BuildContext context, Bloc bloc, E error, Widget? loaded);
typedef BlocLoadingBuilder<Bloc, L extends Loading> = Widget Function(
    BuildContext context, Bloc bloc, L loading, Widget? loaded);
typedef BlocOnGoingOperationBuilder<Bloc, Data> = Widget Function(
    BuildContext context,
    Bloc bloc,
    OnGoingOperationState<Data> operation,
    Widget? loaded);
typedef BlocStateBuilder<Bloc, T> = Widget Function(
    BuildContext context, Bloc bloc, T data, BaseErrors? errors);
typedef BlocStateErrorBuilder<Bloc> = Widget Function(
    BuildContext context, Bloc bloc, Error error);
typedef BlocStateListBuilder<Bloc, T> = List<Widget> Function(
    BuildContext context, Bloc bloc, T data, BaseErrors? errors);
typedef BlocStateListener<Bloc, S> = FutureOr<bool> Function(
    BuildContext context, Bloc bloc, S state);
