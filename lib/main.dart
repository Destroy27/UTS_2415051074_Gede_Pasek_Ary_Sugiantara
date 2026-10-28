import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'providers/merchant_provider.dart';
import 'repositories/merchant_repository.dart';
import 'screens/add_inventory_screen.dart';
import 'screens/catalog_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/inventory_list_screen.dart';
import 'screens/profile_screen.dart';
import 'services/merchant_database_service.dart';
import 'services/product_api_service.dart';
import 'widgets/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool supabaseReady = false;
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.publishableKey,
      );
      supabaseReady = true;
    } catch (_) {
      supabaseReady = false;
    }
  }

  final ProductApiService apiService = ProductApiService();
  final MerchantDatabaseService databaseService = MerchantDatabaseService(
    supabaseInitialized: supabaseReady,
  );
  final MerchantRepository repository = MerchantRepository(
    apiService: apiService,
    databaseService: databaseService,
  );

  runApp(LapakPintarApp(repository: repository));
}

/// Root widget aplikasi LapakPintar (UTS Pemrograman Mobile).
///
/// Memasang [ChangeNotifierProvider] di atas [MaterialApp] agar seluruh
/// screen (termasuk halaman yang di-push melalui Navigator) berbagi state
/// [MerchantProvider] yang sama.
class LapakPintarApp extends StatefulWidget {
  const LapakPintarApp({super.key, this.repository});

  final MerchantRepository? repository;

  @override
  State<LapakPintarApp> createState() => _LapakPintarAppState();
}

class _LapakPintarAppState extends State<LapakPintarApp> {
  late final MerchantProvider _provider;

  @override
  void initState() {
    super.initState();
    final MerchantRepository repo = widget.repository ??
        MerchantRepository(
          apiService: ProductApiService(),
          databaseService: MerchantDatabaseService(supabaseInitialized: false),
        );
    _provider = MerchantProvider(repository: repo)..initializeData();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MerchantProvider>.value(
      value: _provider,
      child: MaterialApp(
        title: 'LapakPintar - UTS Pemrograman Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F6B4A),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const LapakPintarMainShell(),
      ),
    );
  }
}

class LapakPintarMainShell extends StatefulWidget {
  const LapakPintarMainShell({super.key});

  @override
  State<LapakPintarMainShell> createState() => _LapakPintarMainShellState();
}

class _LapakPintarMainShellState extends State<LapakPintarMainShell> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final MerchantProvider provider = context.watch<MerchantProvider>();

    final List<Widget> pages = <Widget>[
      HomeScreen(onNavigateTab: _selectTab),
      const CatalogListScreen(),
      const InventoryListScreen(),
      AddInventoryScreen(
        onSavedJumpToInventory: () => _selectTab(2),
      ),
      const ProfileScreen(),
    ];

    return AppShell(
      currentIndex: _selectedIndex,
      onDestinationSelected: _selectTab,
      pages: pages,
      inventoryBadgeCount: provider.summary.needsRestockCount,
      bookmarkBadgeCount: provider.bookmarkCount,
      isCloudConnected: provider.isCloudDatabaseActive,
    );
  }
}
