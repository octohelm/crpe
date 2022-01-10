import 'package:crpeapp/flutter/flutter.dart';

import 'kube_pkg_state.dart';

class BlocKubePkg extends HydratedCubit<KubePkgState> {
  static BlocKubePkg read(BuildContext context) {
    return context.read<BlocKubePkg>();
  }

  static BlocKubePkg watch(BuildContext context) {
    return context.watch<BlocKubePkg>();
  }

  BlocKubePkg() : super(KubePkgState(list: []));

  @override
  KubePkgState? fromJson(Map<String, dynamic> json) {
    return KubePkgState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(KubePkgState state) {
    return state.toJson();
  }

  add(KubePkg pkg) {
    emit(state.add(pkg));
  }
}
