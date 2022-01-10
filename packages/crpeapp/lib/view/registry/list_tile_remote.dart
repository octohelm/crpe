import 'package:crpe/registry.dart';
import 'package:crpeapp/flutter/flutter.dart';
import 'package:crpeapp/view/scaffold.dart';
import 'package:rxdart/rxdart.dart';

class ListTileRemote extends HookWidget {
  final RegistryRemoteOptions remote;
  final Function()? onTap;
  final bool? selected;

  const ListTileRemote({
    required this.remote,
    this.onTap,
    this.selected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var ready$ = useMemoized(() => BehaviorSubject<bool>(), []);

    useObservableEffect(() {
      Future<bool> check() async {
        try {
          await RegistryRemote(remote).apiCheck();
          return true;
        } catch (_) {}
        return false;
      }

      return Rx.merge([
        Stream.periodic(const Duration(seconds: 3))
            .asyncMap((_) async => await check()),
        Stream.fromFuture(check()),
      ]).doOnData(ready$.add);
    }, [remote]);

    return ListTile(
      onTap: onTap,
      selected: selected ?? false,
      title: const Text("容器镜像源"),
      subtitle: Text(remote.text()),
      trailing: StreamBuilder<bool>(
        stream: ready$,
        builder: (ctx, as) {
          return ActiveStatus(
            size: 10,
            active: as.data,
          );
        },
      ),
    );
  }
}
