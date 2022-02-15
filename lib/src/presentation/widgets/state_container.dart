import 'dart:async';

import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:flutter/material.dart';

import 'state_container_defs.dart';

class StateContainer<Data, StateType> extends StatefulWidget {
  static const String _DefaultLoadingMessage = "loading";
  final String defaultLoadingMessage;
  final StateType state;
  final bool listenToOperation;
  final VoidCallback? retry;
  final StateBuilder<Data> builder;
  final StateListener<StateType>? listener;
  final StateErrorBuilder<Error>? errorBuilder;
  final StateLoadingBuilder<Loading>? loadingBuilder;
  final StateOnGoingOperationBuilder<Data>? onGoingOperationBuilder;
  final StateListener<SuccessfulOperationState<Data>>? onSuccess;
  final StateListener<FailedOperationState<Data>>? onFailure;
  final Widget Function(BuildContext context, Widget child)? buildChild;
  final Widget? Function(
      BuildContext context,
      String? loadingMessage,
      Stream<double>? progress,
      VoidCallback? onCancel,
      Widget? child) buildLoading;
  final Widget? Function(BuildContext context, String? message,
      VoidCallback? retry, Widget? child) buildError;

  const StateContainer(
      {Key? key,
      required this.builder,
      required this.buildLoading,
      required this.buildError,
      required this.state,
      this.buildChild,
      this.defaultLoadingMessage = _DefaultLoadingMessage,
      this.listenToOperation = false,
      this.listener,
      this.errorBuilder,
      this.loadingBuilder,
      this.onGoingOperationBuilder,
      this.onSuccess,
      this.onFailure,
      this.retry})
      : super(key: key);

  @override
  _StateContainerState<Data, StateType> createState() =>
      _StateContainerState<Data, StateType>();
}

class _StateContainerState<Data, StateType>
    extends State<StateContainer<Data, StateType>> {
  static const _switchDuration = Duration(milliseconds: 250);

  Loaded<Data>? _state;
  final List<StateType> _operationStates = [];
  Operation? _operation;

  Future<void> checkOperations(BuildContext context) async {
    if (_operationStates.isNotEmpty && _operation == null) {
      final state = _operationStates.first;
      if (state is Operation) {
        await startOperation(context, state);
        bool handled = false;
        if (widget.listener != null) {
          handled = await widget.listener!(context, state);
        }
        if (!handled) {
          await defaultListener(context, state);
        }
        await endOperation(context, state);
      }
      checkOperations(context);
    }
  }

  Future<void> handleOperation(
      BuildContext context, StateType operationState) async {
    if (operationState is Operation) {
      if (!_operationStates.contains(operationState)) {
        _operationStates.add(operationState);
      }
      return checkOperations(context);
    }
  }

  void _stateListener(BuildContext context, StateType state) async {
    if (state is Operation) {
      await handleOperation(context, state);
    }
  }

  void _listenToOperation(BuildContext context, StateType state) {
    WidgetsBinding.instance!.addPostFrameCallback((_) async {
      _stateListener(context, state);
    });
  }

  Future<void> defaultListener(BuildContext context, StateType state) async {
    if (state is FailedOperationState<Data>) {
      if (widget.onFailure != null) {
        await widget.onFailure!(context, state);
      }
    } else if (state is SuccessfulOperationState<Data>) {
      if (widget.onSuccess != null) {
        await widget.onSuccess!(context, state);
      }
    }
  }

  Future<void> startOperation(BuildContext context, Operation state) async {
    _operation = state is Operation ? state : _operation;
  }

  Future<void> endOperation(BuildContext context, Operation state) {
    _operationStates.remove(state as dynamic);
    _operation = null;
    return checkOperations(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    BaseErrors? errors;
    if (state is Loaded<Data>) {
      _state = state;
    } else if (state is Error) {
      errors = BaseErrors(message: state.response.message);
    }
    if (state is FailedOperationState<Data>) {
      errors = state.errors;
      errors = errors?.withMessage(state.errorMessage);
    }
    Widget? child =
        _state != null ? widget.builder(context, _state!.data, errors) : null;
    if (state is Loading) {
      if (widget.loadingBuilder != null) {
        child = widget.loadingBuilder!(
          context,
          state,
          child,
        );
      } else {
        final loadingMessage = widget.defaultLoadingMessage;
        child = widget.buildLoading(
          context,
          loadingMessage,
          null,
          null,
          child,
        );
      }
    } else if (state is OnGoingOperationState<Data>) {
      if (widget.onGoingOperationBuilder != null) {
        child = widget.onGoingOperationBuilder!(
          context,
          state,
          child,
        );
      } else if (!state.silent) {
        child = widget.buildLoading(
          context,
          state.loadingMessage,
          state.progress,
          state.token != null ? () => state.token!.cancel() : null,
          child,
        );
      }
    } else if (state is Error) {
      if (widget.errorBuilder != null) {
        child = widget.errorBuilder!(
          context,
          state,
          child,
        );
      } else {
        child = widget.buildError(
          context,
          state.response.message,
          widget.retry,
          child,
        );
      }
    }
    child = child as Widget;
    if (widget.listenToOperation) {
      _listenToOperation(context, state);
    }
    if (widget.buildChild != null) {
      return widget.buildChild!(context, child);
    } else {
      return child;
    }
  }
}
