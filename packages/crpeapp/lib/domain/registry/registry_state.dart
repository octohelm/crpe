import 'package:crpe/registry.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part '__generated__/registry_state.freezed.dart';
part '__generated__/registry_state.g.dart';

@freezed
class RegistryState with _$RegistryState {
  RegistryState._();

  factory RegistryState({
    String? selected,
    @Default({}) Map<String, RegistryRemoteOptions> remotes,
  }) = _RegistryState;

  factory RegistryState.fromJson(Map<String, dynamic> json) =>
      _RegistryState.fromJson(json);

  String get current =>
      remotes[selected ?? ""]?.endpoint ?? remotes.keys.firstOrNull ?? "";

  RegistryRemoteOptions remote(String endpoint) {
    return remotes[endpoint]!;
  }
}

@freezed
class RegistryServiceInfo with _$RegistryServiceInfo {
  RegistryServiceInfo._();

  factory RegistryServiceInfo({
    required String ip,
    required int port,
  }) = _RegistryServiceInfo;

  factory RegistryServiceInfo.fromJson(Map<String, dynamic> json) =>
      _RegistryServiceInfo.fromJson(json);

  String get endpoint => "http://${ip}:${port}";
}
