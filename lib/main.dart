import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        publishableKey: SupabaseConfig.publishableKey,
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
    final TextTheme baseTextTheme = GoogleFonts.interTextTheme();
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0B6E4F),
      brightness: Brightness.light,
      surface: const Color(0xFFF8FAF9),
      primary: const Color(0xFF0B6E4F),
    );

    return ChangeNotifierProvider<MerchantProvider>.value(
      value: _provider,
      child: MaterialApp(
        title: 'LapakPintar - UTS Pemrograman Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
          textTheme: baseTextTheme.apply(
            bodyColor: const Color(0xFF1A1D1A),
            displayColor: const Color(0xFF1A1D1A),
          ),
          scaffoldBackgroundColor: const Color(0xFFF8FAF9),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1A1D1A),
            elevation: 0,
            scrolledUnderElevation: 1,
            centerTitle: false,
            titleTextStyle: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D1A),
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              textStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            elevation: 0,
            height: 68,
            indicatorColor: colorScheme.primary.withValues(alpha: 0.10),
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.selected)) {
                return GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                );
              }
              return GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(color: colorScheme.primary, size: 24);
              }
              return const IconThemeData(color: Color(0xFF6B7280), size: 24);
            }),
          ),
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
