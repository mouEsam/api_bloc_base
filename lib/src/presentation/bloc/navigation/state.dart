import 'package:equatable/equatable.dart';

import 'sailor_bloc.dart';

abstract class NavigationState extends Equatable implements Type {
  const NavigationState();

  void push(Sailor sailor, String routeName) {
    sailor.pushDestructively(routeName);
  }

  @override
  get stringify => true;
  @override
  get props => [];
}

class MainPageState extends NavigationState {}
