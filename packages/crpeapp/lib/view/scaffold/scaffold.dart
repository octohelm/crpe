import 'package:crpeapp/flutter/flutter.dart';

class ScaffoldWithBottomNavigation extends HookWidget {
  final List<RouteMeta> routes;
  final Drawer? drawer;

  const ScaffoldWithBottomNavigation({
    Key? key,
    required this.routes,
    this.drawer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _selectedIndex = useState(0);
    final selected = routes.elementAt(_selectedIndex.value);

    return ScaffoldContext.value(
      value: ScaffoldContext(
        current: selected,
        drawer: drawer,
        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Theme.of(context).unselectedWidgetColor,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex.value,
          onTap: (index) => _selectedIndex.value = index,
          items: [
            ...routes.map(
              (e) => BottomNavigationBarItem(icon: e.icon, label: e.label),
            ),
          ],
        ),
      ),
      child: selected.widget,
    );
  }
}

class ScaffoldContext {
  static ScaffoldContext of(BuildContext context) {
    return context.read<ScaffoldContext>();
  }

  static Widget value({
    required ScaffoldContext value,
    Widget? child,
  }) {
    return Provider<ScaffoldContext>.value(
      value: value,
      child: child,
    );
  }

  final BottomNavigationBar? bottomNavigationBar;
  final Drawer? drawer;
  final RouteMeta? current;

  const ScaffoldContext({
    this.bottomNavigationBar,
    this.drawer,
    this.current,
  });
}

class RouteMeta {
  Icon icon;
  String label;
  Widget widget;

  RouteMeta({
    required this.icon,
    required this.label,
    required this.widget,
  });
}
