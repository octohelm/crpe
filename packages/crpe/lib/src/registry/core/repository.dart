import 'dart:io';

import 'interfaces.dart';
import 'paths.dart';
import 'store_blob.dart';
import 'store_linked_blob.dart';
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
    blobService = StoreBlob(root);
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
