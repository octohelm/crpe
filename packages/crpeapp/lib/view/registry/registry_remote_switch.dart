import 'package:crpe/registry.dart';
import 'package:crpeapp/common/flutter.dart';
import 'package:crpeapp/domain/registry.dart';

import 'list_tile_remote.dart';
import 'page_edit_remote.dart';

class RegistryRemoteSwitch extends HookWidget {
  const RegistryRemoteSwitch({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var blocRegistry = BlocRegistry.watch(context);

    if (blocRegistry.state.current.isEmpty) {
      return ListTile(
        onTap: () {
          PageEditRemote.show(context);
        },
        title: const Text("请添加容器镜像源"),
        trailing: const Icon(Icons.add),
      );
    }

    var remote = blocRegistry.state.remote(blocRegistry.state.current);

    return Select<RegistryRemoteOptions>(
      title: const Text("切换容器镜像源"),
      options: blocRegistry.state.remotes.values.toList(),
      value: remote,
      onSelected: (selected) {
        blocRegistry.switchRemote(selected.endpoint);
      },
      builder: (context, children) {
        return SingleChildScrollView(
          child: SafeArea(
            child: Column(
              children: children,
            ),
          ),
        );
      },
      optionBuilder: (context, option, selected) {
        return ListTileRemote(
          onTap: () {
            option.select();
          },
          selected: option.value == selected.value,
          remote: option.value,
        );
      },
      tileBuilder: (context, selected) {
        return ListTileRemote(
            remote: remote,
            onTap: () {
              selected.showOptions(context);
            });
      },
    );
  }
}
