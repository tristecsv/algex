import 'package:algex/ui/pages/home_page.dart';
import 'package:algex/ui/state/settings_notifier.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    minimumSize: Size(300, 600),
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _settingsNotifier = SettingsNotifier();

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      notifier: _settingsNotifier,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'e^x - Serie de Taylor',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueAccent,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}
