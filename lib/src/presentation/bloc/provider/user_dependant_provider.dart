import 'package:api_bloc_base/src/data/_index.dart';
import 'package:api_bloc_base/src/domain/entity/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/user/base_user_bloc.dart';
import 'package:dartz/dartz.dart';

abstract class UserDependantProvider<Input, Output,
        Profile extends BaseProfile<Profile>>
    extends IndependentProvider<Input, Output>
    with
        UserDependantProviderMixin<Input, Output, Profile>,
        UserDependantProviderStateMixin<Input, Output, Profile> {
  final BaseUserBloc<Profile> userBloc;

  UserDependantProvider({
    required this.userBloc,
    Input? initialInput,
    Result<Either<ResponseEntity, Input>>? singleDataSource,
    Either<ResponseEntity, Stream<Input>>? dataStreamSource,
    Stream<Either<ResponseEntity, Input>>? streamDataSource,
    LifecycleObserver? appLifecycleObserver,
    List<ProviderMixin> providers = const [],
    List<Stream<ProviderState>> sources = const [],
    bool enableRefresh = true,
    bool enableRetry = true,
    bool canRunWithoutListeners = true,
    bool refreshOnActive = true,
    bool fetchOnCreate = true,
  }) : super(
          initialInput: initialInput,
          singleDataSource: singleDataSource,
          streamDataSource: streamDataSource,
          dataStreamSource: dataStreamSource,
          appLifecycleObserver: appLifecycleObserver,
          sources: sources,
          providers: providers,
          enableRefresh: enableRefresh,
          enableRetry: enableRetry,
          refreshOnActive: refreshOnActive,
          canRunWithoutListeners: canRunWithoutListeners,
          fetchOnCreate: fetchOnCreate,
        );
}
