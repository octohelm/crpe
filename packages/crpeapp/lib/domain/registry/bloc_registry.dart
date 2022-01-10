import 'dart:io';

import 'package:crpe/kubepkg.dart';
import 'package:crpe/registry.dart';
import 'package:crpeapp/common/flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'registry_state.dart';

class BlocRegistry extends HydratedCubit<RegistryState> {
  static BlocRegistry read(BuildContext context) {
    return context.read<BlocRegistry>();
  }

  static BlocRegistry watch(BuildContext context) {
    return context.watch<BlocRegistry>();
  }

  final Directory root;

  BlocRegistry(this.root) : super(RegistryState());

  @override
  RegistryState? fromJson(Map<String, dynamic> json) {
    return RegistryState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(RegistryState state) {
    return state.toJson();
  }

  RegistryLocal get local => RegistryLocal(root.path);

  RegistryProxy get proxy => RegistryProxy(
        local: local,
        remote: currentRemote!,
      );

  KubePkgRegistry get kubePkgRegistry =>
      KubePkgRegistry.fromRegistryLocal(local);

  Future<String?> getWifiIP() async {
    return await NetworkInfo().getWifiIP();
  }

  RegistryRemote? get currentRemote {
    return state.current.isNotEmpty
        ? RegistryRemote(state.remote(state.current))
        : null;
  }

  void switchRemote(String endpoint) {
    emit(state.copyWith(selected: endpoint));
  }

  void updateRemote(RegistryRemoteOptions remote) {
    emit(state.copyWith(remotes: {
      ...state.remotes,
      remote.endpoint: remote,
    }));
  }
}
