import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/data_service.dart';
import 'state/app_state.dart';
import 'screens/home_screen.dart';

/// Single-venue app for now — the venue a shopper lands on.
/// Multi-venue selection (QR/deep link) comes later; swapping this id
/// is the only step needed to point the app at a different pilot venue.
const _venueId = 'city_center_mall';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Skip entirely when unconfigured — DataService falls back to bundled
  // demo data, so there's nothing to connect to yet.
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }
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
      context.read<AppState>().loadMallData(_venueId);
    });
  }

  @override
  Widget build(BuildContext context) => const HomeScreen();
}
