import 'package:crpeapp/flutter/flutter.dart';
import 'package:crpeapp/page_kube_pkg_add.dart';
import 'package:crpeapp/view/kube_pkg.dart';
import 'package:crpeapp/view/scaffold.dart';

class PageKubePkg extends HookWidget {
  static get topic => Topic(
        icon: const Icon(Icons.inventory_outlined),
        label: '部署包',
        widget: const PageKubePkg(),
      );

  const PageKubePkg({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var st = ScaffoldTopicProvider.of(context);

    return Scaffold(
      bottomNavigationBar: st.bottomNavigationBar,
      appBar: AppBar(
        title: Text(st.current.label),
        actions: [
          IconButton(
            onPressed: () {
              PageKubePkgAdd.show(context);
            },
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: const ListKubePkg(),
    );
  }
}
