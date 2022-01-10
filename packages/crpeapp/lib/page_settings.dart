import 'package:crpeapp/flutter/flutter.dart';
import 'package:crpeapp/page_setting_remote.dart';
import 'package:crpeapp/registry/bloc_registry.dart';

class PageSettings extends HookWidget {
  static show(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: false,
        builder: (context) => const PageSettings(),
      ),
    );
  }

  const PageSettings({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var config = BlocRegistry.watch(context).state;

    return Scaffold(
      appBar: AppBar(
        title: const Text("配置"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: const Text("镜像源"),
              onTap: () => PageSettingRemote.show(context),
              subtitle: config.remote?.let((r) {
                    return Text(r.text());
                  }) ??
                  const Text("未设置"),
            ),
          ],
        ),
      ),
    );
  }
}
