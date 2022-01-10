import 'package:crpe/registry.dart';

import 'proxy_blob.dart';
import 'proxy_manifest.dart';
import 'proxy_tag.dart';

class RegistryProxy implements Registry {
  RegistryRemote remote;
  Registry local;

  RegistryProxy({
    required this.remote,
    required this.local,
  });

  @override
  Future<Repository> repository(name) async {
    return ProxyRepository(
      local: await local.repository(name),
      remote: remote,
    );
  }
}

class ProxyRepository implements Repository {
  RegistryRemote remote;
  Repository local;

  ProxyRepository({
    required this.remote,
    required this.local,
  });

  @override
  String get name {
    var host = Uri.parse(remote.options.endpoint).host;
    if (local.name.startsWith(host)) {
      return local.name.replaceFirst(host + "/", "");
    }
    return local.name;
  }

  @override
  BlobService blobs() {
    return ProxyBlob(
      name: name,
      remote: remote,
      local: local.blobs(),
    );
  }

  @override
  ManifestService manifests() {
    return ProxyManifest(
      name: name,
      remote: remote,
      local: local.manifests(),
    );
  }

  @override
  TagService tags() {
    return ProxyTag(
      name: name,
      remote: remote,
      local: local.tags(),
    );
  }
}
