import 'package:api_bloc_base/api_bloc_base.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/worker_bloc.dart';
import 'package:equatable/equatable.dart';

class FormBlocData<Data> extends Equatable {
  final Data data;
  final bool isEdit;

  const FormBlocData(this.data, this.isEdit);

  @override
  get props => [this.data, this.isEdit];
}

mixin FormMixin<Data> on WorkerBloc<FormBlocData<Data>> {
  static const EDIT_OPERATION = "EDIT_OPERATION";

  late Data data;
  bool isEdit = false;

  get currentData => FormBlocData(data, isEdit);

  void editMode() {
    isEdit = true;
    emitCurrent();
  }

  void viewMode() {
    isEdit = false;
    emitCurrent();
  }

  Future<bool> Function()? get goBack {
    if (!isEdit) {
      return null;
    } else {
      return () async {
        isEdit = false;
        emitCurrent();
        return false;
      };
    }
  }
}
