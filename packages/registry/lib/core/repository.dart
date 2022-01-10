import 'dart:io';

import 'package:registry/core/paths.dart';
import 'package:registry/core/store_linked_blob.dart';

import 'interfaces.dart';
import 'store_blob.dart';
import 'store_manifest.dart';
import 'store_tag.dart';

class LocalRepository implements Repository {
  Directory root;
  late BlobService blobService;

  @override
  String name;

  LocalRepository({
    required this.root,
    required this.name,
  }) {
    blobService = StoreBlob(name: name, root: root);
  }

  @override
  TagService tags() => StoreTag(name: name, root: root);

  @override
  BlobService blobs() => StoreLinkedBlob(
        name: name,
        linkPathFuncs: [
          (name, digest) => PathLayerLink(name, digest).path(root),
        ],
        blobService: blobService,
      );

  @override
  ManifestService manifests() {
    return StoreManifest(
      name: name,
      blobService: StoreLinkedBlob(
        name: name,
        linkPathFuncs: [
          (name, digest) => PathManifestRevisionLink(name, digest).path(root),
          (name, digest) => PathLayerLink(name, digest).path(root),
        ],
        blobService: blobService,
      ),
    );
  }
}
