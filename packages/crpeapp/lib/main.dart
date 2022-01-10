import 'package:crpeapp/flutter/flutter.dart';
import 'package:crpeapp/kubepkg/bloc_kube_pkg.dart';
import 'package:crpeapp/page_kube_pkg.dart';
import 'package:crpeapp/page_registry.dart';
import 'package:crpeapp/registry/registry.dart';
import 'package:crpeapp/theme.dart';
import 'package:crpeapp/view/scaffold.dart';

void main() async {
  FlutterServicesBinding.ensureInitialized();

  var s = await HydratedStorage.build(
    storageDirectory: await getTemporaryDirectory(),
  );

  HydratedBlocOverrides.runZoned(
    () => runApp(const App()),
    storage: s,
  );
}

class App extends HookWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CacheDirectoryProvider(
      child: PageMain(),
    );
  }
}

class PageMain extends HookWidget {
  const PageMain({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BlocRegistry>(
          lazy: false,
          create: (_) => BlocRegistry(CacheDirectoryProvider.read(context)),
        ),
        BlocProvider<BlocKubePkg>(
          lazy: false,
          create: (_) => BlocKubePkg(),
        ),
      ],
      child: MaterialApp(
        theme: theme,
        home: ScaffoldTopicProvider(
          topics: [
            PageRegistry.topic,
            PageKubePkg.topic,
          ],
        ),
      ),
    );
  }
}
