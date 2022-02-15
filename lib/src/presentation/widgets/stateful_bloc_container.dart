import 'dart:async';

import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:flutter/material.dart';

import 'state_container_defs.dart';

class StatefulBlocContainer<Data, StateType extends BlocState,
    Bloc extends StatefulBloc<Data, StateType>> extends StatefulWidget {
  static const String _DefaultLoadingMessage = "loading";
  final String defaultLoadingMessage;
  final bool showCancelOnLoading;
  final bool treatErrorAsOperation;
  final BlocStateBuilder<Bloc, Data>? bodyBuilder;
  final BlocStateListener<Bloc, StateType>? listener;
  final BlocStateListener<Bloc, SuccessfulOperationState<Data>>? onSuccess;
  final BlocStateListener<Bloc, FailedOperationState<Data>>? onFailure;
  final BlocStateBuilder<Bloc, Data>? pageBuilder;
  final Widget Function(
      BuildContext context,
      Bloc bloc,
      String? loadingMessage,
      Stream<double>? progress,
      VoidCallback? onCancel,
      Widget? body)? buildPage;
  final Widget Function(BuildContext context, Bloc bloc, Error error)
      errorBuilder;

  const StatefulBlocContainer({
    Key? key,
    this.bodyBuilder,
    this.pageBuilder,
    required this.buildPage,
    required this.errorBuilder,
    this.listener,
    this.onSuccess,
    this.onFailure,
    this.showCancelOnLoading = true,
    this.treatErrorAsOperation = true,
    this.defaultLoadingMessage = _DefaultLoadingMessage,
  }) : super(key: key);

  @override
  _StatefulBlocContainerState<Data, StateType, Bloc> createState() =>
      _StatefulBlocContainerState<Data, StateType, Bloc>();
}

class _StatefulBlocContainerState<Data, StateType extends BlocState,
        Bloc extends StatefulBloc<Data, StateType>>
    extends State<StatefulBlocContainer<Data, StateType, Bloc>> {
  Loaded<Data>? _state;
  final List<StateType> _operationStates = [];
  Operation? _operation;

  Future<void> checkOperations(BuildContext context, Bloc bloc) async {
    if (_operationStates.isNotEmpty && _operation == null) {
      final state = _operationStates.first;
      if (state is Operation) {
        await startOperation(context, bloc, state as Operation);
        bool handled = false;
        if (widget.listener != null) {
          handled = await widget.listener!(context, bloc, state);
        }
        if (!handled) {
          await defaultListener(context, bloc, state);
        }
        await endOperation(context, bloc, state as Operation);
      }
      checkOperations(context, bloc);
    }
  }

  Future<void> handleOperation(
      BuildContext context, Bloc bloc, StateType operationState) async {
    if (operationState is Operation) {
      if (!_operationStates.contains(operationState)) {
        _operationStates.add(operationState);
      }
      return checkOperations(context, bloc);
    }
  }

  void _stateListener(BuildContext context, Bloc bloc, StateType state) async {
    if (state is Operation) {
      await handleOperation(context, bloc, state);
    }
  }

  void _listenToErrorAsFailedOperation(
      BuildContext context, Bloc bloc, FailedOperationState<Data> state) {
    WidgetsBinding.instance!.addPostFrameCallback((_) async {
      _stateListener(context, bloc, state as StateType);
    });
  }

  Future<void> defaultListener(
      BuildContext context, Bloc bloc, StateType state) async {
    if (state is FailedOperationState<Data>) {
      if (widget.onFailure != null) {
        await widget.onFailure!(context, bloc, state);
      }
    } else if (state is SuccessfulOperationState<Data>) {
      if (widget.onSuccess != null) {
        await widget.onSuccess!(context, bloc, state);
      }
    }
  }

  Future<void> startOperation(
      BuildContext context, Bloc bloc, Operation state) async {
    _operation = state is Operation ? state : _operation;
  }

  Future<void> endOperation(BuildContext context, Bloc bloc, Operation state) {
    _operationStates.remove(state as dynamic);
    _operation = null;
    return checkOperations(context, bloc);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<Bloc, StateType>(
      listener: (context, state) {
        final bloc = context.read<Bloc>();
        _stateListener(context, bloc, state);
      },
      builder: (context, state) {
        final bloc = context.watch<Bloc>();
        VoidCallback? onCancel;
        String? loadingMessage;
        Stream<double>? progress;
        BaseErrors? errors;
        if (state is Loaded<Data>) {
          _state = state;
        }
        if (state is Loading) {
          onCancel =
              widget.showCancelOnLoading ? () => Navigator.pop(context) : null;
          loadingMessage = widget.defaultLoadingMessage;
        }
        if (state is OnGoingOperationState<Data> && !state.silent) {
          loadingMessage = state.loadingMessage;
          if (bloc is WorkerMixin<Data>) {
            onCancel = () => (bloc as WorkerMixin<Data>)
                .cancelOperation(operationTag: state.operationTag);
          }
          progress = state.progress;
        } else if (state is FailedOperationState<Data>) {
          errors = state.errors;
          errors = errors?.withMessage(state.errorMessage);
        }
        if (state is Error) {
          errors = BaseErrors(message: state.response.message);
        }
        Widget page;
        if (state is Error && _state == null) {
          page = widget.errorBuilder(context, bloc, state);
        } else {
          final isLoaded = _state != null;
          Widget? body;
          if (isLoaded && widget.bodyBuilder != null) {
            body = widget.bodyBuilder!(context, bloc, _state!.data, errors);
          }
          if (widget.treatErrorAsOperation && state is Error) {
            _listenToErrorAsFailedOperation(
                context,
                bloc,
                FailedOperationState<Data>.message(_state!.data,
                    errors: errors,
                    errorMessage: state.response.message,
                    operationTag: "",
                    silent: false,
                    retry: bloc is Refreshable
                        ? () => (bloc as Refreshable).refetchData()
                        : null));
          }
          if (isLoaded && widget.pageBuilder != null) {
            page = widget.pageBuilder!(context, bloc, _state!.data, errors);
          } else if (widget.buildPage != null) {
            page = widget.buildPage!(
                context, bloc, loadingMessage, progress, onCancel, body);
          } else {
            page = body ?? Container();
          }
        }
        return page;
      },
    );
  }
}
