import 'dart:io';

import 'package:crpe/flutter/flutter.dart';
import 'package:crpe/registry/mirror/mirror.dart';
import 'package:crpe/registry/registry.dart';
import 'package:crpe/registry/remote/remote.dart';
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

  RegistryRemote get remote {
    if (state.remote == null) {
      throw Exception("镜像源未配置");
    }

    return RegistryRemote(state.remote!);
  }

  LocalRegistry get registry => LocalRegistry(root.path);

  HttpServer? _httpServer;

  bool isServerOn() {
    return _httpServer != null;
  }

  void updateRemote(RegistryRemoteOptions remote) {
    emit(state.copyWith(remote: remote));
  }

  serve() async {
    var ip = await NetworkInfo().getWifiIP();
    int port = 6006;

    _httpServer = await HttpServer.bind(ip, port);

    RegistryRoutes.serve(_httpServer!, registry);

    emit(state.copyWith(
      service: RegistryServiceInfo(
        ip: ip!,
        port: port,
      ),
    ));
  }

  RegistryMirror get mirror => RegistryMirror(registry, remote);

  shutdown() async {
    await _httpServer?.close();

    _httpServer = null;

    emit(state.copyWith(
      service: null,
    ));
  }

  Future<Map<String, bool>> validateImages(Map<String, String> images) async {
    Map<String, bool> ret = {};

    for (var image in images.keys) {
      var r = await mirror.validate(
        image,
        digest: images[image]?.let((v) => v != "" ? v : null),
      );

      ret[image] = r;
    }

    return ret;
  }
}
