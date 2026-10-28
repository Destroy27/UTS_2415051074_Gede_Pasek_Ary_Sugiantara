import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/breakpoint.dart';
import '../core/student_identity.dart';

/// Reusable Widget #3: Kerangka navigasi responsif aplikasi LapakPintar.
///
/// - Pada kondisi Compact & Medium: menggunakan [NavigationBar] di bawah.
/// - Pada kondisi Expanded (≥840px): menggunakan [NavigationRail] di samping kiri.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.pages,
    required this.inventoryBadgeCount,
    required this.bookmarkBadgeCount,
    required this.isCloudConnected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<Widget> pages;
  final int inventoryBadgeCount;
  final int bookmarkBadgeCount;
  final bool isCloudConnected;

  static const List<_NavDestination> _destinations = <_NavDestination>[
    _NavDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Beranda',
    ),
    _NavDestination(
      icon: Icons.local_shipping_outlined,
      selectedIcon: Icons.local_shipping_rounded,
      label: 'Katalog',
    ),
    _NavDestination(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
      label: 'Stok',
    ),
    _NavDestination(
      icon: Icons.add_business_outlined,
      selectedIcon: Icons.add_business_rounded,
      label: 'Tambah',
    ),
    _NavDestination(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final LayoutCategory category = layoutCategoryOf(constraints.maxWidth);
        final Widget activePage = pages[currentIndex];
        final ColorScheme colors = Theme.of(context).colorScheme;

        if (category == LayoutCategory.expanded) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAF9),
            body: Row(
              children: <Widget>[
                Container(
                  width: constraints.maxWidth >= 1080 ? 240 : 72,
                  color: Colors.white,
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: constraints.maxWidth >= 1080
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.store_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            if (constraints.maxWidth >= 1080) ...<Widget>[
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  student.appName,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A1D1A),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: NavigationRail(
                          extended: constraints.maxWidth >= 1080,
                          selectedIndex: currentIndex,
                          onDestinationSelected: onDestinationSelected,
                          backgroundColor: Colors.transparent,
                          indicatorColor: colors.primary.withValues(alpha: 0.08),
                          labelType: constraints.maxWidth >= 1080
                              ? NavigationRailLabelType.none
                              : NavigationRailLabelType.all,
                          destinations: List<NavigationRailDestination>.generate(
                            _destinations.length,
                            (int index) {
                              final _NavDestination d = _destinations[index];
                              return NavigationRailDestination(
                                icon: _buildBadgedIcon(index, d.icon),
                                selectedIcon: _buildBadgedIcon(index, d.selectedIcon),
                                label: Text(
                                  d.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: constraints.maxWidth >= 1080
                            ? Row(
                                children: <Widget>[
                                  Icon(
                                    isCloudConnected
                                        ? Icons.cloud_done_outlined
                                        : Icons.storage_outlined,
                                    size: 16,
                                    color: isCloudConnected
                                        ? Colors.green.shade600
                                        : const Color(0xFF6B7280),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isCloudConnected
                                        ? 'Supabase Cloud'
                                        : 'Mode Lokal',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              )
                            : Icon(
                                isCloudConnected
                                    ? Icons.cloud_done_outlined
                                    : Icons.storage_outlined,
                                size: 18,
                                color: isCloudConnected
                                    ? Colors.green.shade600
                                    : const Color(0xFF6B7280),
                              ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                Expanded(child: activePage),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF9),
          body: activePage,
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: List<NavigationDestination>.generate(
              _destinations.length,
              (int index) {
                final _NavDestination d = _destinations[index];
                return NavigationDestination(
                  icon: _buildBadgedIcon(index, d.icon),
                  selectedIcon: _buildBadgedIcon(index, d.selectedIcon),
                  label: d.label,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgedIcon(int index, IconData iconData) {
    if (index == 1 && bookmarkBadgeCount > 0) {
      return Badge.count(
        count: bookmarkBadgeCount,
        backgroundColor: const Color(0xFF0B6E4F),
        child: Icon(iconData),
      );
    }
    if (index == 2 && inventoryBadgeCount > 0) {
      return Badge.count(
        count: inventoryBadgeCount,
        backgroundColor: Colors.orange.shade600,
        child: Icon(iconData),
      );
    }
    return Icon(iconData);
  }
}

class _NavDestination {
  const _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
