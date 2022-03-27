import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef FamilyWidgetBuilder<Bloc extends Cubit> = Widget Function(
    BuildContext context, Bloc bloc);

class FamilyBuilder<Arg, Bloc extends Cubit,
    FamilyBloc extends Family<Arg, Bloc>> extends StatelessWidget {
  final Arg arg;
  final bool? unique;
  final Family<Arg, Bloc>? family;
  final FamilyWidgetBuilder<Bloc> builder;

  const FamilyBuilder({
    Key? key,
    required this.arg,
    required this.builder,
    this.family,
    this.unique,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final family = this.family ?? context.read<FamilyBloc>();
    return FamilyBlocProvider<Arg, Bloc>(
      arg: arg,
      unique: unique,
      family: family,
      builder: builder,
    );
  }
}

class FamilyBlocProvider<Arg, Bloc extends Cubit> extends StatefulWidget {
  final Arg arg;
  final bool? unique;
  final Family<Arg, Bloc> family;
  final FamilyWidgetBuilder<Bloc> builder;

  FamilyBlocProvider({
    required this.arg,
    required this.family,
    required this.builder,
    this.unique,
  }) : super(key: ValueKey(arg));

  @override
  State<FamilyBlocProvider<Arg, Bloc>> createState() =>
      _FamilyBlocProviderState<Arg, Bloc>();
}

class _FamilyBlocProviderState<Arg, Bloc extends Cubit>
    extends State<FamilyBlocProvider<Arg, Bloc>>
    with FamilyListenerMixin<FamilyBlocProvider<Arg, Bloc>> {
  late final Bloc _bloc;

  @override
  void initState() {
    _bloc = widget.family(widget.arg, this, unique: widget.unique);
    super.initState();
  }

  @override
  void dispose() {
    widget.family.clear(widget.arg, this, unique: widget.unique);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: widget.builder(context, _bloc),
    );
  }
}
