import 'package:crpe/app/kubepkg/kubepkg.dart';
import 'package:crpe/app/registry/registry.dart';
import 'package:crpe/flutter/flutter.dart';

class ListKubePkg extends HookWidget {
  const ListKubePkg({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final blocKubePkg = BlocKubePkg.read(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          ...blocKubePkg.state.list.map((kubePkg) => ListTileKubePkg(
                kubePkg: kubePkg,
              ))
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
    return ListTile(
      leading: Icon(
        Icons.group_work_outlined,
        size: Theme.of(context).textTheme.headline3?.fontSize,
      ),
      title: Text(kubePkg.name),
      subtitle: FutureBuilder<Map<String, bool>>(
          future: BlocRegistry.read(context).validateImages(kubePkg.images),
          builder: (context, s) {
            var ready = s.data?.values.every((v) => v) ?? false;

            return DefaultTextStyle.merge(
              child: Text.rich(
                TextSpan(children: [
                  const TextSpan(
                    text: "VERSION ",
                    style: TextStyle(
                      fontSize: 10,
                    ),
                  ),
                  TextSpan(
                    text: kubePkg.version,
                  ),
                  const TextSpan(
                    text: "   MANIFESTS ",
                    style: TextStyle(
                      fontSize: 10,
                    ),
                  ),
                  TextSpan(
                    text: "${kubePkg.manifests.length}",
                  ),
                  const TextSpan(
                    text: "   IMAGES ",
                    style: TextStyle(
                      fontSize: 10,
                    ),
                  ),
                  TextSpan(
                    text: "${kubePkg.images.length}",
                    style: TextStyle(
                      color: ready ? Colors.green : Colors.red,
                    ),
                  ),
                ]),
              ),
            );
          }),
    );
  }
}
