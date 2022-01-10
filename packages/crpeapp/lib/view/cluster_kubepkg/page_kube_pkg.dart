import 'package:crpe/kubepkg.dart';
import 'package:crpeapp/domain/cluster.dart';
import 'package:crpeapp/domain/registry.dart';
import 'package:crpeapp/flutter/flutter.dart';
import 'package:crpeapp/flutter/ui.dart';
import 'package:crpeapp/view/registry.dart';
import 'package:crpeapp/view/scaffold.dart';
import 'package:rxdart/rxdart.dart';

import 'kube_pkg_progress.dart';
import 'page_kube_pkg_add.dart';

class PageKubePkg extends HookWidget {
  static get route => RouteMeta(
        icon: const Icon(Icons.widgets),
        label: '应用',
        widget: const PageKubePkg(),
      );

  const PageKubePkg({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var st = ScaffoldContext.of(context);
    var cluster = BlocCluster.watch(context).current;

    return Scaffold(
      drawer: st.drawer,
      bottomNavigationBar: st.bottomNavigationBar,
      appBar: AppBar(
        title: Text(st.current?.label ?? ""),
        actions: [
          IconButton(
            onPressed: () {
              PageKubePkgAdd.show(context);
            },
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: Column(
        children: [
          const RegistryRemoteSwitch(),
          const Divider(height: 0),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...?cluster.pkgs?.let(
                    (pkgs) => pkgs.keys.map((key) {
                      var pkg = pkgs[key]!;

                      return ListTileKubePkg(kubePkg: pkg);
                    }),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ListTileKubePkg extends HookWidget {
  final KubePkg kubePkg;

  const ListTileKubePkg({
    required this.kubePkg,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var blocRegistry = BlocRegistry.read(context);
    var blocCluster = BlocCluster.watch(context);

    var kubePkgRoot = blocRegistry.kubePkgRegistry;

    var ss$ = useMemoized(() {
      return BehaviorSubject<Progress>();
    }, []);

    var createTgz = useMemoized(() {
      return () async {
        var resolvedPkg = await kubePkg.resolveDigests(blocRegistry.proxy);

        blocCluster.updatePkg(
          blocCluster.current.name,
          resolvedPkg.withTgzDigest(null),
        );

        var tgzDigest = await kubePkgRoot.upload(
          await kubePkg.tgz$(blocRegistry.proxy, process$: ss$),
        );

        blocCluster.updatePkg(
          blocCluster.current.name,
          resolvedPkg.withTgzDigest(tgzDigest),
        );
      };
    }, []);

    return ListTile(
      onTap: () {
        if (kubePkg.tgzCreated) {
          showAlert(
            context,
            content: const Text("是否重新生成安装包 ？"),
            onConfirm: () {
              createTgz();
            },
          );
        } else {
          createTgz();
        }
      },
      title: Text(kubePkg.metadata.name.toUpperCase()),
      subtitle: Text(
        kubePkg.spec.version,
      ),
      trailing: SizedBox(
        width: 100,
        child: StreamBuilder<Progress>(
          stream: ss$,
          builder: (c, as) {
            return KubePkgProgress(
              progress: kubePkg.tgzCreated ? null : as.data,
            );
          },
        ),
      ),
    );
  }
}
