import 'package:freezed_annotation/freezed_annotation.dart';

part '__generated__/kube_pkg_state.freezed.dart';
part '__generated__/kube_pkg_state.g.dart';

@freezed
class KubePkgState with _$KubePkgState {
  KubePkgState._();

  factory KubePkgState({
    required List<KubePkg> list,
  }) = _KubePkgState;

  factory KubePkgState.fromJson(Map<String, dynamic> json) =>
      _KubePkgState.fromJson(json);

  KubePkgState add(KubePkg pkg) {
    return copyWith(
      list: [
        ...list,
        pkg,
      ],
    );
  }
}

@freezed
class KubePkg with _$KubePkg {
  KubePkg._();

  factory KubePkg({
    required String name,
    required String version,
    required Map<String, String> images,
    required List<String> manifests,
  }) = _KubePkg;

  factory KubePkg.fromJson(Map<String, dynamic> json) =>
      _KubePkg.fromJson(json);
}
