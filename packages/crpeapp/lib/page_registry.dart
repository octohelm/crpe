import 'package:crpeapp/flutter/flutter.dart';
import 'package:crpeapp/page_settings.dart';
import 'package:crpeapp/view/registry_syncer.dart';
import 'package:crpeapp/view/scaffold.dart';
import 'package:crpeapp/view/service_toggle.dart';

class PageRegistry extends HookWidget {
  static get topic => Topic(
        icon: const Icon(Icons.sensors_outlined),
        label: '仓库',
        widget: const PageRegistry(),
      );

  const PageRegistry({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final st = ScaffoldTopicProvider.of(context);

    return Scaffold(
      bottomNavigationBar: st.bottomNavigationBar,
      appBar: AppBar(
        title: Text(st.current.label),
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
      body: Column(
        children: const [
          Divider(color: Colors.transparent),
          ServiceToggle(),
          Divider(),
          Expanded(
            child: RegistrySyncer(),
          ),
        ],
      ),
    );
  }
}
