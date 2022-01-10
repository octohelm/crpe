import 'dart:async';
import 'dart:io';

import 'interfaces.dart';
import 'paths.dart';
import 'repository.dart';

class LocalRegistry implements Registry {
  late Directory root;

  LocalRegistry(String base) {
    root = Directory("$base/docker/registry/v2");
  }

  Future<List<Repository>> repositories() async {
    List<Repository> repos = [];

    var r = PathRepositories().path(root);

    walk(FileSystemEntity p) async {
      if (p is Directory) {
        for (var e in await p.list().toList()) {
          if (e is Directory) {
            if (e.path.endsWith("_manifests")) {
              repos.add(LocalRepository(
                root: root,
                name: e.parent.path.substring(r.path.length + 1),
              ));
              break;
            }
            await walk(e);
          }
        }
      }
    }

    await walk(r);

    return repos;
  }

  @override
  Future<Repository> repository(name) async {
    return LocalRepository(
      root: root,
      name: name,
    );
  }
}
