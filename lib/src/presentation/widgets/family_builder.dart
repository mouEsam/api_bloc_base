import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef FamilyWidgetBuilder<Bloc extends BaseCubit> = Widget Function(
    BuildContext context, Bloc bloc);

class FamilyBuilder<Arg, Bloc extends BaseCubit,
    FamilyBloc extends Family<Arg, Bloc>> extends StatelessWidget {
  final Arg arg;
  final Family<Arg, Bloc>? family;
  final FamilyWidgetBuilder<Bloc> builder;

  const FamilyBuilder({
    Key? key,
    required this.arg,
    required this.builder,
    this.family,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final family = this.family ?? context.read<FamilyBloc>();
    return FamilyBlocProvider<Arg, Bloc>(
      arg: arg,
      family: family,
      builder: builder,
    );
  }
}

class FamilyBlocProvider<Arg, Bloc extends BaseCubit> extends StatefulWidget {
  final Arg arg;
  final Family<Arg, Bloc> family;
  final FamilyWidgetBuilder<Bloc> builder;

  FamilyBlocProvider({
    required this.arg,
    required this.family,
    required this.builder,
  }) : super(key: ValueKey(arg));

  @override
  State<FamilyBlocProvider<Arg, Bloc>> createState() =>
      _FamilyBlocProviderState<Arg, Bloc>();
}

class _FamilyBlocProviderState<Arg, Bloc extends BaseCubit>
    extends State<FamilyBlocProvider<Arg, Bloc>>
    with FamilyListenerMixin<FamilyBlocProvider<Arg, Bloc>> {
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
