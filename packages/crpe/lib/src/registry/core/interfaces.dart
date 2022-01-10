import 'dart:io';

import 'package:crpe/registry.dart';

typedef LinkPathFunc = FileSystemEntity Function(String name, Digest digest);

abstract class TagService {
  Future<List<String>> all();

  Future<List<String>> lookup(Descriptor descriptor);

  Future<Descriptor> get(String tag);

  Future<void> tag(String tag, Descriptor descriptor);

  Future<void> untag(String tag);
}

abstract class BlobStatter {
  Future<Descriptor> stat(Digest digest);
}

abstract class BlobDeleter {
  Future<void> delete(Digest digest);
}

abstract class BlobProvider {
  Future<Stream<List<int>>> openRead(
    Digest digest, {
    int? start,
    int? end,
  });

  Future<List<int>> get(Digest digest);
}

abstract class BlobIngester {
  Future<IOSink> openWrite(Digest digest);

  Future<Digest> upload(Stream<List<int>> contents, {Digest? digest});
}

abstract class BlobService
    with BlobStatter, BlobDeleter, BlobProvider, BlobIngester {}

abstract class ManifestService {
  Future<bool> exists(Digest digest);

  Future<Manifest> get(Digest digest);

  Future<Digest> put(Digest digest, Manifest manifest);

  Future<void> delete(Digest digest);
}

abstract class Repository {
  String get name;

  BlobService blobs();

  TagService tags();

  ManifestService manifests();
}

abstract class Registry {
  Future<Repository> repository(String name);
}
