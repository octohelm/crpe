import 'package:crpe/src/registry/core.dart';
import 'package:crpe/src/registry/remote.dart';

import 'package:crpe/src/registry/schema.dart';

class ProxyTag implements TagService {
  String name;
  RegistryRemote remote;
  TagService local;

  ProxyTag({
    required this.name,
    required this.remote,
    required this.local,
  });

  @override
  Future<List<String>> all() async {
    return local.all();
  }

  @override
  Future<List<String>> lookup(desc) async {
    return local.lookup(desc);
  }

  @override
  Future<Descriptor> get(tag) async {
    try {
      var m = await remote.manifest(name, tag);
      var d = Descriptor(
        digest: m.digest,
      );
      await local.tag(tag, d);
      return d;
    } catch (e) {
      return await local.get(tag);
    }
  }

  @override
  Future<void> tag(t, desc) async {
    return;
  }

  @override
  Future<void> untag(t) async {
    return;
  }
}
