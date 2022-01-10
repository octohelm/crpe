import 'package:freezed_annotation/freezed_annotation.dart';

part '__generated__/platform.freezed.dart';
part '__generated__/platform.g.dart';

@freezed
class Platform with _$Platform {
  Platform._();

  factory Platform({
    required String architecture,
    required String os,
    String? variant,
    List<String>? features,
    @JsonKey(name: "os.version") String? osVersion,
    @JsonKey(name: "os.features") List<String>? osFeatures,
  }) = _Platform;

  factory Platform.fromJson(Map<String, dynamic> json) =>
      _Platform.fromJson(json);

  String normalize() {
    return [
      normalizeOS(os),
      ...normalizeArch(architecture, variant ?? ""),
    ].join("/");
  }
}

String normalizeOS(String os) {
  os = os.toLowerCase();

  switch (os) {
    case "macos":
      return "darwin";
  }

  return os;
}

List<String> normalizeArch(String arch, String variant) {
  arch = arch.toLowerCase();
  variant = variant.toLowerCase();

  switch (arch) {
    case "i386":
      arch = "386";
      variant = "";
      break;
    case "x86_64":
    case "x86-64":
      arch = "amd64";
      variant = "";
      break;
    case "aarch64":
    case "arm64":
      arch = "arm64";
      switch (variant) {
        case "8":
        case "v8":
          variant = "";
      }
      break;
    case "armhf":
      arch = "arm";
      variant = "v7";
      break;
    case "armel":
      arch = "arm";
      variant = "v6";
      break;
    case "arm":
      switch (variant) {
        case "":
        case "7":
          variant = "v7";
          break;
        case "5":
        case "6":
        case "8":
          variant = "v$variant";
          break;
      }
  }

  if (variant == "") {
    return [arch];
  }

  return [arch, variant];
}
