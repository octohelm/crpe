import 'dart:io';

import 'package:crpe/src/registry/schema.dart';

abstract class PathSpec {
  FileSystemEntity path(Directory root);
}

class PathBlobData implements PathSpec {
  Digest digest;

  PathBlobData(this.digest);

  @override
  FileSystemEntity path(Directory root) {
    return File(
        "${root.path}/blobs/${digest.alg}/${digest.hash.substring(0, 2)}/${digest.hash}/data");
  }
}

class PathUploads implements PathSpec {
  String uuid;

  PathUploads(this.uuid);

  @override
  FileSystemEntity path(Directory root) {
    return File(
      "${root.path}/_uploads/${uuid}",
    );
  }
}

class PathRepositories implements PathSpec {
  @override
  FileSystemEntity path(Directory root) {
    return Directory("${root.path}/repositories");
  }
}

class PathLayerLink extends PathRepositories {
  String name;
  Digest digest;

  PathLayerLink(this.name, this.digest);

  @override
  FileSystemEntity path(Directory root) {
    return File(
        "${super.path(root).path}/$name/_layers/${digest.alg}/${digest.hash}/link");
  }
}

class PathManifestRevisions extends PathRepositories {
  String name;

  PathManifestRevisions(this.name);

  @override
  FileSystemEntity path(Directory root) {
    return Directory("${super.path(root).path}/$name/_manifests/revisions");
  }
}

class PathManifestRevisionLink extends PathManifestRevisions {
  Digest digest;

  PathManifestRevisionLink(
    String name,
    this.digest,
  ) : super(name);

  @override
  FileSystemEntity path(Directory root) {
    return File("${super.path(root).path}/${digest.alg}/${digest.hash}/link");
  }
}

class PathManifestTags extends PathRepositories {
  String name;

  PathManifestTags(this.name);

  @override
  FileSystemEntity path(Directory root) {
    return Directory("${super.path(root).path}/$name/_manifests/tags");
  }
}

class PathManifestTag extends PathManifestTags {
  String tag;

  PathManifestTag(
    String name,
    this.tag,
  ) : super(name);

  @override
  FileSystemEntity path(Directory root) {
    return Directory("${super.path(root).path}/$tag");
  }
}

class PathManifestTagCurrent extends PathManifestTag {
  PathManifestTagCurrent(
    String name,
    String tag,
  ) : super(name, tag);

  @override
  FileSystemEntity path(Directory root) {
    return File("${super.path(root).path}/current/link");
  }
}

class PathManifestTagIndex extends PathManifestTag {
  PathManifestTagIndex(
    String name,
    String tag,
  ) : super(name, tag);

  @override
  FileSystemEntity path(Directory root) {
    return File("${super.path(root).path}/index");
  }
}

class PathManifestTagIndexEntryLink extends PathManifestTagIndex {
  Digest digest;

  PathManifestTagIndexEntryLink(
    String name,
    String tag,
    this.digest,
  ) : super(name, tag);

  @override
  FileSystemEntity path(Directory root) {
    return File("${super.path(root).path}/${digest.alg}/${digest.hash}/link");
  }
}
