import 'dart:io';

import 'package:crpeapp/flutter/extension/std.dart';
import 'package:crpeapp/flutter/hook.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class CacheDirectoryProvider extends HookWidget {
  static Directory read(BuildContext context) {
    return context.read<Directory>();
  }

  const CacheDirectoryProvider({
    this.child,
    Key? key,
  }) : super(key: key);

  final Widget? child;

  Future<Directory> getCacheDirectory() async {
    return (await Platform.isAndroid
                .ifTrueOrNull(() => getExternalCacheDirectories()))
            ?.getOrNull(0) ??
        (await getTemporaryDirectory());
  }

  @override
  Widget build(BuildContext context) {
    var stateDir = useState<Directory?>(null);

    useObservableEffect(() {
      return Stream.fromFuture(getCacheDirectory()).doOnData((dir) {
        stateDir.value = dir;
      });
    }, []);

    if (stateDir.value == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Provider<Directory>.value(
      value: stateDir.value!,
      child: child,
    );
  }
}
