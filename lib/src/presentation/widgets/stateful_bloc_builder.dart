import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/listenable_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/_index.dart';
import '../bloc/worker/_index.dart';
import 'state_container_defs.dart';

class StatefulBlocBuilder<Data, StateType extends BlocState,
    Bloc extends StatefulBloc<Data, StateType>> extends StatefulWidget {
  static const String _DefaultLoadingMessage = "loading";
  final String defaultLoadingMessage;
  final Bloc? bloc;
  final bool treatErrorAsOperation;
  final BlocStateGenericBuilder<Bloc, Data, StateType> builder;
  final BlocStateListener<Bloc, StateType>? listener;
  final BlocStateListener<Bloc, SuccessfulOperationState<Data>>? onSuccess;
  final BlocStateListener<Bloc, FailedOperationState<Data>>? onFailure;

  const StatefulBlocBuilder({
    Key? key,
    required this.builder,
    this.bloc,
    this.listener,
    this.onSuccess,
    this.onFailure,
    this.treatErrorAsOperation = true,
    this.defaultLoadingMessage = _DefaultLoadingMessage,
  }) : super(key: key);

  @override
  _StatefulBlocBuilderState<Data, StateType, Bloc> createState() =>
      _StatefulBlocBuilderState<Data, StateType, Bloc>();
}

class _StatefulBlocBuilderState<Data, StateType extends BlocState,
        Bloc extends StatefulBloc<Data, StateType>>
    extends State<StatefulBlocBuilder<Data, StateType, Bloc>> {
  Loaded<Data>? _state;
  final List<StateType> _operationStates = [];
  Operation? _operation;

  Bloc get bloc {
    return widget.bloc ?? context.read<Bloc>();
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
        _state = state is Loaded<Data> ? state : _state;
        if (widget.treatErrorAsOperation && state is Error && _state != null) {
          _listenToErrorAsFailedOperation(
            context,
            bloc,
            FailedOperationState<Data>.message(_state!.data,
                errors: BaseErrors(message: state.response.message),
                errorMessage: state.response.message,
                operationTag: "",
                silent: false,
                retry: bloc is Refreshable
                    ? (bloc as Refreshable).refetchData
                    : null),
          );
        }
        return widget.builder(context, bloc, _state?.data, state);
      },
    );
  }
}
