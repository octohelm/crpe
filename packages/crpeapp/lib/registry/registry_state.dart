import 'package:registry/mirror/types.dart';
import 'package:registry/remote/remote.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part '__generated__/registry_state.freezed.dart';
part '__generated__/registry_state.g.dart';

@freezed
class RegistryState with _$RegistryState {
  RegistryState._();

  factory RegistryState({
    RegistryMirrorOptions? mirror,
    RegistryRemoteOptions? remote,
    RegistryServiceInfo? service,
  }) = _RegistryState;

  factory RegistryState.fromJson(Map<String, dynamic> json) =>
      _RegistryState.fromJson(json);
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
}
