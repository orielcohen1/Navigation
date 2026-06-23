import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/data_service.dart';
import 'state/app_state.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(DataService()),
      child: const IndoorNavApp(),
    ),
  );
}

class IndoorNavApp extends StatelessWidget {
  const IndoorNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Indoor Nav',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const _AppLoader(),
    );
  }
}

/// Triggers data load once, then hands off to [HomeScreen].
class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  @override
  void initState() {
    super.initState();
    // Load on first frame so context.read is safe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadMallData();
    });
  }

  @override
  Widget build(BuildContext context) => const HomeScreen();
}
