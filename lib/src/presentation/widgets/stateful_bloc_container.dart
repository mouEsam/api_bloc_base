import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/listenable_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/_index.dart';
import '../bloc/worker/_index.dart';
import 'state_container_defs.dart';

class StatefulBlocContainer<Data, StateType extends BlocState,
    Bloc extends StatefulBloc<Data, StateType>> extends StatefulWidget {
  static const String _DefaultLoadingMessage = "loading";
  final String defaultLoadingMessage;
  final bool showCancelOnLoading;
  final bool treatErrorAsOperation;
  final Bloc? bloc;
  final BlocStateBuilder<Bloc, Data>? buildBody;
  final BlocStateListener<Bloc, StateType>? listener;
  final BlocStateListener<Bloc, SuccessfulOperationState<Data>>? onSuccess;
  final BlocStateListener<Bloc, FailedOperationState<Data>>? onFailure;
  final BlocStateBuilder<Bloc, Data>? buildPage;
  final Widget Function(BuildContext context, Bloc bloc,
      OperationData? operation, Widget? body)? buildWrapper;
  final BlocStateErrorBuilder<Bloc> buildError;

  const StatefulBlocContainer({
    Key? key,
    this.buildBody,
    this.buildPage,
    this.buildWrapper,
    required this.buildError,
    this.bloc,
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

  Bloc get bloc {
    return context.read<Bloc>();
  }

  @override
  void initState() {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      final listenable = bloc;
      if (listenable is ListenableMixin) {
        (listenable as ListenableMixin).addStateListener(this);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    final listenable = bloc;
    if (listenable is ListenableMixin) {
      (listenable as ListenableMixin).removeStateListener(this);
    }
    super.dispose();
  }

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
    final Bloc bloc = widget.bloc ?? context.read<Bloc>();
    final child = buildBloc(context, bloc);
    if (widget.bloc == null) {
      return child;
    } else {
      return BlocProvider.value(
        value: bloc,
        child: child,
      );
    }
  }

  Widget buildBloc(BuildContext context, Bloc bloc) {
    return BlocConsumer<Bloc, StateType>(
      bloc: bloc,
      listener: (context, state) {
        _stateListener(context, bloc, state);
      },
      builder: (context, state) {
        VoidCallback? onCancel;
        OperationData? operationData;
        BaseErrors? errors;
        if (state is Loaded<Data>) {
          _state = state;
        }
        if (state is Loading) {
          operationData = OperationData(
              loadingMessage: widget.defaultLoadingMessage,
              onCancel: widget.showCancelOnLoading
                  ? () => Navigator.pop(context)
                  : null);
        }
        if (state is OnGoingOperationState<Data> && !state.silent) {
          operationData = OperationData(
            loadingMessage:
                state.loadingMessage ?? widget.defaultLoadingMessage,
            progress: state.progress,
            onCancel: state.isCancellable ? () => state.cancel() : null,
          );
        } else if (state is FailedOperationState<Data>) {
          errors = state.errors;
          errors = errors?.withMessage(state.errorMessage);
        }
        if (state is Error) {
          errors = BaseErrors(message: state.response.message);
        }
        Widget page;
        if (state is Error && _state == null) {
          page = widget.buildError(context, bloc, state);
        } else {
          final isLoaded = _state != null;
          Widget? body;
          if (isLoaded && widget.buildBody != null) {
            body = widget.buildBody!(context, bloc, _state!.data, errors);
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
                        ? (bloc as Refreshable).refetchData
                        : null));
          }
          if (isLoaded && widget.buildPage != null) {
            page = widget.buildPage!(context, bloc, _state!.data, errors);
          } else if (widget.buildWrapper != null) {
            page = widget.buildWrapper!(context, bloc, operationData, body);
          } else {
            page = body ?? Container();
          }
        }
        return page;
      },
    );
  }
}
