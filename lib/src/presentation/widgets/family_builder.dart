import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef FamilyWidgetBuilder<Bloc extends BaseCubit> = Widget Function(
    BuildContext context, Bloc bloc);

class FamilyBuilder<Arg, Bloc extends BaseCubit> extends StatefulWidget {
  final Arg arg;
  final Family<Arg, Bloc> family;
  final FamilyWidgetBuilder<Bloc> builder;

  FamilyBuilder({
    required this.arg,
    required this.family,
    required this.builder,
  }) : super(key: ValueKey(arg));

  @override
  State<FamilyBuilder<Arg, Bloc>> createState() =>
      _FamilyBuilderState<Arg, Bloc>();
}

class _FamilyBuilderState<Arg, Bloc extends BaseCubit>
    extends State<FamilyBuilder<Arg, Bloc>>
    with FamilyListenerMixin<FamilyBuilder<Arg, Bloc>> {
  late final Bloc _bloc;

  @override
  void initState() {
    _bloc = widget.family.getBloc(widget.arg, this);
    super.initState();
  }

  @override
  void dispose() {
    widget.family.clearBloc(widget.arg, this);
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
