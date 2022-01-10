import 'package:registry/core/core.dart';
import 'package:registry/remote/remote.dart';
import 'package:registry/schema/distribution.dart';

class ProxyTag implements TagService {
  String name;
  RegistryRemote client;
  TagService local;

  ProxyTag({
    required this.name,
    required this.client,
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
      var m = await client.manifest(name, tag);
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
