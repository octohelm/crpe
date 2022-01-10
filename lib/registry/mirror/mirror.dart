import 'dart:async';

import 'package:crpe/extension/std.dart';
import 'package:crpe/registry/registry.dart';
import 'package:crpe/registry/remote/remote.dart';
import 'package:crpe/registry/schema/distribution.dart';
import 'package:crpe/registry/schema/manifest.dart';

import 'types.dart';

typedef RequestJob = Function(MirrorJob job);

class RegistryMirror {
  final RegistryRemote remote;
  final LocalRegistry local;
  RegistryMirrorOptions? options;

  RegistryMirror(
    this.local,
    this.remote, {
    this.options,
  });

  Future<bool> validate(String imageName, {String? digest}) async {
    var nameAndSha = imageName.split("@");
    if (nameAndSha.length == 2) {
      return exists(
        nameAndSha[0],
        digest: Digest.parse(nameAndSha[1]),
      );
    }
    var nameAndTag = imageName.split(":");
    if (nameAndTag.length == 2) {
      return exists(
        nameAndTag[0],
        tag: nameAndTag[1],
        digest: digest?.let((d) => d != "" ? Digest.parse(d) : null),
      );
    }
    return false;
  }

  Future<bool> exists(
    String name, {
    String? tag,
    Digest? digest,
  }) async {
    var repo = await local.repository(name);

    if (tag != null && digest == null) {
      try {
        var d = await repo.tags().get(tag);
        return await exists(
          name,
          digest: d.digest,
          tag: tag,
        );
      } catch (e) {
        return false;
      }
    }

    if (digest != null) {
      try {
        var m = await repo.manifests().get(digest);

        if (m is ManifestListSpec) {
          for (var sub in m.manifests) {
            if (options?.platforms?.contains(sub.platform!.normalize()) ??
                true) {
              var ex = await exists(
                name,
                digest: sub.digest,
              );
              if (!ex) {
                return false;
              }
            }
          }
        }

        if (m is ManifestSpec) {
          for (var l in m.layers) {
            try {
              var d = await repo.blobs().stat(l.digest!);
              if (d.size != l.size) {
                return false;
              }
            } catch (e) {
              return false;
            }
          }
        }

        return true;
      } catch (e) {
        return false;
      }
    }

    return false;
  }
}
