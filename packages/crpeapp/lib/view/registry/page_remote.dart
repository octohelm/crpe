import 'package:crpeapp/common/flutter.dart';
import 'package:crpeapp/domain/registry.dart';

import 'list_tile_remote.dart';
import 'page_edit_remote.dart';

class PageRemote extends HookWidget {
  static show(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: false,
        builder: (context) => const PageRemote(),
      ),
    );
  }

  const PageRemote({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var blobRegistry = BlocRegistry.watch(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("容器镜像源管理"),
        actions: [
          IconButton(
            onPressed: () {
              PageEditRemote.show(context);
            },
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: ListView(
        children: [
          ...blobRegistry.state.remotes.values.map(
            (remote) => ListTileRemote(
              onTap: () {
                PageEditRemote.show(context, remote: remote);
              },
              remote: remote,
            ),
          )
        ],
      ),
    );
  }
}
