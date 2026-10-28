import 'package:flutter/material.dart';

import '../core/breakpoint.dart';
import '../core/student_identity.dart';
import 'identity_header.dart';

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
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront,
      label: 'Beranda',
    ),
    _NavDestination(
      icon: Icons.local_shipping_outlined,
      selectedIcon: Icons.local_shipping,
      label: 'Katalog API',
    ),
    _NavDestination(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'Stok Lapak',
    ),
    _NavDestination(
      icon: Icons.add_business_outlined,
      selectedIcon: Icons.add_business,
      label: 'Tambah Stok',
    ),
    _NavDestination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profil & Laba',
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
            body: Row(
              children: <Widget>[
                NavigationRail(
                  extended: constraints.maxWidth >= 1080,
                  selectedIndex: currentIndex,
                  onDestinationSelected: onDestinationSelected,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    child: Column(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          child: const Icon(Icons.store, size: 22),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          student.appName,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        LayoutBadge(category: category),
                      ],
                    ),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Chip(
                          avatar: Icon(
                            isCloudConnected ? Icons.cloud_done : Icons.storage,
                            size: 16,
                            color: isCloudConnected
                                ? Colors.green.shade700
                                : colors.primary,
                          ),
                          label: Text(
                            isCloudConnected ? 'Supabase Cloud' : 'Mode Lokal',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  ),
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
                        label: Text(d.label),
                      );
                    },
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: activePage),
              ],
            ),
          );
        }

        return Scaffold(
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
        child: Icon(iconData),
      );
    }
    if (index == 2 && inventoryBadgeCount > 0) {
      return Badge.count(
        count: inventoryBadgeCount,
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
