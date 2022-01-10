import 'dart:io';

import 'package:crpe/extension.dart';

import '../schema.dart';
import 'interfaces.dart';
import 'paths.dart';

class StoreTag implements TagService {
  String name;
  Directory root;

  StoreTag({
    required this.name,
    required this.root,
  });

  @override
  Future<List<String>> all() async {
    var tagRoot = PathManifestTags(name).path(root) as Directory;
    return tagRoot
        .list()
        .where((e) => e is Directory)
        .map((e) => e.path.substring(tagRoot.path.length + 1))
        .toList();
  }

  @override
  Future<List<String>> lookup(Descriptor desc) async {
    var allTags = await all();

    List<String> matchedTags = [];
    for (var tag in allTags) {
      try {
        var d = await get(tag);
        if (d.digest == desc.digest) {
          matchedTags.add(tag);
        }
      } catch (e) {
        // ignore
      }
    }

    return matchedTags;
  }

  @override
  Future<Descriptor> get(String tag) async {
    var tagLink = PathManifestTagCurrent(name, tag).path(root) as File;

    if (!await tagLink.exists()) {
      throw ErrTagUnknown(tag: tag);
    }

    return Descriptor(
      digest: await Digest.fromLinkFile(tagLink),
    );
  }

  @override
  Future<void> tag(String t, Descriptor desc) async {
    await desc.digest?.let(
      (d) => Future.wait([
        PathManifestTagCurrent(name, t).path(root) as File,
        PathManifestTagIndexEntryLink(name, t, d).path(root) as File,
      ].map(d.putLinkFile)),
    );
  }

  @override
  Future<FileSystemEntity> untag(String t) async {
    return PathManifestTag(name, t).path(root).delete(recursive: true);
  }
}
