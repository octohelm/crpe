import 'dart:io';
import 'dart:typed_data';

import 'package:registry/core/paths.dart';
import 'package:registry/schema/distribution.dart';
import 'package:registry/schema/errorcodes.dart';

import 'interfaces.dart';

class StoreBlob implements BlobService, BlobIngester {
  String name;
  Directory root;

  StoreBlob({
    required this.name,
    required this.root,
  });

  @override
  Future<Descriptor> stat(digest) async {
    var dataFile = PathBlobData(digest).path(root) as File;

    if (await dataFile.exists()) {
      var fi = await dataFile.stat();

      return Descriptor(
        digest: digest,
        mediaType: "application/octet-stream",
        size: fi.size,
      );
    }

    throw ErrBlobUnknown(digest: digest);
  }

  @override
  Future<void> delete(digest) {
    var fileBlobData = PathBlobData(digest).path(root) as File;
    return fileBlobData.delete(recursive: true);
  }

  @override
  Future<Uint8List> get(digest) {
    var fileBlobData = PathBlobData(digest).path(root) as File;
    return fileBlobData.readAsBytes();
  }

  @override
  Future<Stream<List<int>>> openRead(
    digest, {
    int? start,
    int? end,
  }) async {
    var fileBlobData = PathBlobData(digest).path(root) as File;
    return fileBlobData.openRead(start, end);
  }

  @override
  Future<IOSink> openWrite(digest) async {
    var fileBlobData = PathBlobData(digest).path(root) as File;
    await fileBlobData.create(recursive: true);
    return fileBlobData.openWrite();
  }
}
