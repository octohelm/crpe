import 'package:crpeapp/domain/cluster.dart';
import 'package:crpeapp/domain/registry.dart';
import 'package:crpeapp/flutter/flutter.dart';
import 'package:crpeapp/theme.dart';
import 'package:crpeapp/view/cluster.dart';

import 'flutter/upgrader/upgrader.dart';

void main() async {
  FlutterServicesBinding.ensureInitialized();

  var s = await HydratedStorage.build(
    storageDirectory: await getApplicationSupportDirectory(),
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
    return _withProviders(
      context,
      MaterialApp(
        theme: theme,
        home: HookBuilder(builder: (context) {
          Upgrader.use(context);

          return const ScaffoldCluster();
        }),
      ),
    );
  }

  Widget _withProviders(BuildContext context, Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BlocRegistry>(
          create: (_) => BlocRegistry(CacheDirectoryProvider.read(context)),
        ),
        BlocProvider<BlocCluster>(
          create: (_) => BlocCluster(),
        ),
      ],
      child: child,
    );
  }
}
