import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FamilyFactory<Arg, Bloc extends Cubit> {
  final FamilyFactoryCreator<Arg, Bloc> _createFamily;

  const FamilyFactory(this._createFamily);

  Bloc get(Arg arg, {bool? unique, bool? keepAlive}) {
    return _createFamily(arg, unique: unique, keepAlive: keepAlive);
  }
}

typedef FamilyFactoryCreator<Arg, Bloc> = Bloc Function(
  Arg arg, {
  bool? unique,
  bool? keepAlive,
});

class FamilySeed<F extends Family> {
  final F _family;

  const FamilySeed(this._family);
}

abstract class FamilyReader {
  FamilySeed<F> family<F extends Family>();
  Bloc call<Arg, Bloc extends Cubit>(
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
        this.family,
        this.arg,
        this.keepAlive,
        this.unique,
      ];
}

class _FamilyConsumerState extends State<FamilyConsumer>
    with FamilyListenerMixin<FamilyConsumer>, _FamilyReaderMixin {
  final Set<_Hook> _hooks = {};

  @override
  FamilySeed<F> family<F extends Family>() {
    return FamilySeed(context.read<F>());
  }

  @override
  Bloc call<Arg, Bloc extends Cubit>(
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
    _hooks.forEach((hook) {
      hook.family.clear(
        hook.arg,
        this,
        unique: hook.unique,
        keepAlive: hook.keepAlive,
      );
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, this, widget.child);
  }
}
