import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/base/tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef TreeWidgetBuilder<Bloc extends Cubit> = Widget Function(
    BuildContext context, Bloc bloc);

class TreeBuilder<Bloc extends Cubit, TreeBloc extends Tree<Bloc>>
    extends StatelessWidget {
  final bool? unique;
  final Tree<Bloc>? tree;
  final TreeWidgetBuilder<Bloc> builder;

  const TreeBuilder({
    Key? key,
    required this.builder,
    this.tree,
    this.unique,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tree = this.tree ?? context.read<TreeBloc>();
    return TreeBlocProvider<Bloc>(
      unique: unique,
      tree: tree,
      builder: builder,
    );
  }
}

class TreeBlocProvider<Bloc extends Cubit> extends StatefulWidget {
  final bool? unique;
  final Tree<Bloc> tree;
  final TreeWidgetBuilder<Bloc> builder;

  TreeBlocProvider({
    required this.tree,
    required this.builder,
    this.unique,
  }) : super(key: ValueKey(tree));

  @override
  State<TreeBlocProvider<Bloc>> createState() => _TreeBlocProviderState<Bloc>();
}

class _TreeBlocProviderState<Bloc extends Cubit>
    extends State<TreeBlocProvider<Bloc>>
    with TreeListenerMixin<TreeBlocProvider<Bloc>> {
  late final Bloc _bloc;

  @override
  void initState() {
    _bloc = widget.tree(this, unique: widget.unique);
    super.initState();
  }

  @override
  void dispose() {
    widget.tree.clear(this, unique: widget.unique);
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
