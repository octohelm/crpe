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

  Map<String, String> images() {
    Map<String, String> _images = {};

    for (var pkg in list) {
      for (var tag in pkg.images.keys) {
        if (!_images.containsKey(tag) || _images[tag] == "") {
          _images[tag] = pkg.images[tag]!;
        }
      }
    }

    return _images;
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
