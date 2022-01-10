import 'package:crpe/app/registry/registry.dart';
import 'package:crpe/flutter/flutter.dart';

class ServiceToggle extends HookWidget {
  const ServiceToggle({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var blocRegistry = BlocRegistry.watch(context);

    return ListTile(
      onTap: () async {
        if (blocRegistry.isServerOn()) {
          await blocRegistry.shutdown();
        } else {
          await blocRegistry.serve();
        }
      },
      onLongPress: () {
        blocRegistry.state.service?.let(
          (s) => Clipboard.setData(
            ClipboardData(
                text: "${s.ip}:${s.port}/docker.io/library/nginx:alpine"),
          ),
        );
      },
      leading: Icon(
        blocRegistry.isServerOn() ? Icons.sensors : Icons.sensors_off,
        size: Theme.of(context).textTheme.headline3?.fontSize,
      ),
      title: Text(blocRegistry.isServerOn() ? "服务运行中" : "服务已关闭"),
      subtitle: blocRegistry.state.service?.let(
            (s) => Text("serving on ${s.ip}:${s.port}"),
          ) ??
          const Text("点此启动"),
    );
  }
}
