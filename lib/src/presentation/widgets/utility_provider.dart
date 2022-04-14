import 'package:api_bloc_base/src/presentation/bloc/base/_index.dart';
import 'package:flutter/material.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';

class MultiUtilityProvider extends Nested {
  MultiUtilityProvider({
    Key? key,
    required List<SingleChildWidget> providers,
    Widget? child,
    TransitionBuilder? builder,
  }) : super(
          key: key,
          children: providers,
          child: builder != null
              ? Builder(
                  builder: (context) => builder(context, child),
                )
              : child,
        );
}

mixin UtilityProviderSingleChildWidget on SingleChildWidget {}

class UtilityProvider<T extends UtilityBloc> extends Provider<T>
    with UtilityProviderSingleChildWidget {
  /// {@macro repository_provider}
  UtilityProvider({
    Key? key,
    required Create<T> create,
    Widget? child,
    bool? lazy,
  }) : super(
          key: key,
          create: create,
          dispose: (_, __) {},
          child: child,
          lazy: lazy,
        );

  /// Takes a repository and a [child] which will have access to the repository.
  /// A new repository should not be created in `RepositoryProvider.value`.
  /// Repositories should always be created using the default constructor
  /// within the [Create] function.
  UtilityProvider.value({
    Key? key,
    required T value,
    Widget? child,
  }) : super.value(
          key: key,
          value: value,
          child: child,
        );

  /// Method that allows widgets to access a repository instance as long as
  /// their `BuildContext` contains a [UtilityProvider] instance.
  static T of<T extends UtilityBloc>(BuildContext context,
      {bool listen = false}) {
    try {
      return Provider.of<T>(context, listen: listen);
    } on ProviderNotFoundException catch (e) {
      if (e.valueType != T) rethrow;
      throw FlutterError(
        '''
        UtilityProvider.of() called with a context that does not contain a repository of type $T.
        No ancestor could be found starting from the context that was passed to UtilityProvider.of<$T>().

        This can happen if the context you used comes from a widget above the UtilityProvider.

        The context used was: $context
        ''',
      );
    }
  }
}
