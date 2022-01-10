import 'package:crpe/app/page_kube_pkg_add.dart';
import 'package:crpe/app/page_settings.dart';
import 'package:crpe/app/view/kube_pkg.dart';
import 'package:crpe/app/view/service_toggle.dart';
import 'package:crpe/flutter/flutter.dart';

class PageHome extends HookWidget {
  const PageHome({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CR Pocket Edition"),
        actions: [
          IconButton(
            onPressed: () {
              PageSettings.show(context);
            },
            icon: const Icon(
              Icons.settings,
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          PageKubePkgAdd.show(context);
        },
        child: const Icon(Icons.add),
        tooltip: "添加 KubePkg",
      ),
      body: Column(
        children: const [
          Divider(color: Colors.transparent),
          ServiceToggle(),
          Divider(),
          ListKubePkg(),
        ],
      ),
    );
  }
}
