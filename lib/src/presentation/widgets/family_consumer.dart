import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FamilySeed<F extends Family> {
  final F _family;

  const FamilySeed(this._family);
}

abstract class FamilyReader {
  FamilySeed<F> call<F extends Family>();

  Bloc get<Arg, Bloc extends Cubit>(
    FamilySeed<Family<Arg, Bloc>> family,
    Arg arg, {
    bool? unique,
    bool? keepAlive,
  });
}

mixin _FamilyReaderMixin implements FamilyReader {}

typedef FamilyConsumerBuilder = Widget Function(
  BuildContext context,
  FamilyReader reader,
  Widget? child,
);

class _Hook<Arg, Bloc extends Cubit> extends Equatable {
  final Family<Arg, Bloc> family;
  final Arg arg;
  final bool? keepAlive;
  final bool? unique;

  const _Hook(
    this.family,
    this.arg,
    this.keepAlive,
    this.unique,
  );

  @override
  List<Object?> get props => [
        family,
        arg,
        keepAlive,
        unique,
      ];
}

class FamilyConsumer extends StatefulWidget {
  const FamilyConsumer({
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  final Widget? child;
  final FamilyConsumerBuilder builder;

  @override
  State<FamilyConsumer> createState() => _FamilyConsumerState();
}

class _FamilyConsumerState extends State<FamilyConsumer>
    with FamilyListenerMixin<FamilyConsumer>, _FamilyReaderMixin {
  final Set<_Hook> _hooks = {};

  @override
  FamilySeed<F> call<F extends Family>() {
    assert(mounted);
    return FamilySeed(context.read<F>());
  }

  @override
  Bloc get<Arg, Bloc extends Cubit>(
    FamilySeed<Family<Arg, Bloc>> seed,
    Arg arg, {
    bool? unique,
    bool? keepAlive,
  }) {
    final hook = _Hook(seed._family, arg, keepAlive, unique);
    return registerHook<Arg, Bloc>(hook);
  }

  Bloc registerHook<Arg, Bloc extends Cubit>(_Hook<Arg, Bloc> hook) {
    final bloc = hook.family(
      hook.arg,
      this,
      keepAlive: hook.keepAlive,
      unique: hook.unique,
    );
    _hooks.add(hook);
    return bloc;
  }

  @override
  void dispose() {
    for (final hook in _hooks) {
      hook.family.clear(
        hook.arg,
        this,
        unique: hook.unique,
        keepAlive: hook.keepAlive,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, this, widget.child);
  }
}

class MyBloc extends Cubit<int> {
  MyBloc(int arg) : super(arg);
}

class MyFamily extends Family<int, MyBloc> {
  @override
  MyBloc createBloc(int arg) {
    return MyBloc(arg);
  }
}

class MyTest extends StatelessWidget {
  const MyTest({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FamilyConsumer(
      builder: (context, reader, child) {
        final bloc = reader.get(reader<MyFamily>(), 0);
        return const SizedBox();
      },
    );
  }
}
