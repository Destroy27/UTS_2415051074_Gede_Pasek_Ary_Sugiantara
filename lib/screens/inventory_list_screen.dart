import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/breakpoint.dart';
import '../core/currency_formatter.dart';
import '../models/merchant_item.dart';
import '../models/merchant_summary.dart';
import '../providers/merchant_provider.dart';
import '../widgets/identity_header.dart';
import '../widgets/merchant_item_card.dart';
import '../widgets/state_views.dart';
import 'add_inventory_screen.dart';
import 'edit_inventory_screen.dart';

/// Screen #6: Daftar Stok Lapak & Catatan Kulakan.
class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    MerchantItem item,
  ) async {
    final int? itemId = item.id;
    if (itemId == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Hapus Barang?',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus "${item.productTitle}" (Stok: ${item.stockQty} unit) dari database lapak?',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Hapus',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<MerchantProvider>().deleteItem(itemId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Barang "${item.productTitle}" telah dihapus.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _openEditScreen(BuildContext context, MerchantItem item) async {
    await Navigator.of(context).push<MerchantItem>(
      MaterialPageRoute<MerchantItem>(
        builder: (_) => EditInventoryScreen(item: item),
      ),
    );
  }

  Future<void> _openAddModalScreen(BuildContext context) async {
    await Navigator.of(context).push<MerchantItem>(
      MaterialPageRoute<MerchantItem>(
        builder: (_) => const AddInventoryScreen(isPushedRoute: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MerchantProvider provider = context.watch<MerchantProvider>();
    final MerchantSummary summary = provider.summary;
    final List<MerchantItem> items = provider.filteredInventoryItems;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final LayoutCategory category = layoutCategoryOf(constraints.maxWidth);
        final int columns = gridColumnsFor(category);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF9),
          appBar: AppBar(
            title: const Text('Stok Lapak'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Muat Ulang',
                onPressed: () => provider.loadInventory(),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                color: const Color(0xFF6B7280),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opsi',
                onSelected: (String value) {
                  if (value == 'simulate_error') {
                    provider.loadInventory(simulateError: true);
                  } else if (value == 'reload') {
                    provider.loadInventory();
                  }
                },
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'reload',
                    child: Text('Sinkronisasi Database'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'simulate_error',
                    child: Text('Simulasi Error Database'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: LayoutBadge(category: category),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddModalScreen(context),
            backgroundColor: const Color(0xFF0B6E4F),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              'Barang Baru',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          body: _buildBody(
            context: context,
            provider: provider,
            summary: summary,
            items: items,
            columns: columns,
          ),
        );
      },
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required MerchantProvider provider,
    required MerchantSummary summary,
    required List<MerchantItem> items,
    required int columns,
  }) {
    if (provider.isLoadingInventory) {
      return const LoadingStateView(
        message: 'Memuat data inventaris dari database...',
      );
    }

    if (provider.inventoryError != null) {
      return ErrorStateView(
        title: 'Gagal Memuat Database',
        message: provider.inventoryError!,
        onRetry: () => provider.loadInventory(),
      );
    }

    final List<String> statuses = <String>[
      'Semua',
      ...MerchantItem.validStatuses,
    ];

    return RefreshIndicator(
      color: const Color(0xFF0B6E4F),
      onRefresh: () => provider.loadInventory(),
      child: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  IdentityHeader(
                    subtitle: provider.isCloudDatabaseActive
                        ? 'Database: Supabase PostgreSQL'
                        : 'Mode Lokal (isi URL & Key untuk cloud)',
                    dense: true,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        _SummaryItem(
                          label: 'Jenis',
                          value: '${summary.totalSkuCount} SKU',
                        ),
                        _SummaryItem(
                          label: 'Unit Stok',
                          value: '${summary.totalUnitsInStock}',
                        ),
                        _SummaryItem(
                          label: 'Modal',
                          value: CurrencyFormatter.formatCompactRupiah(
                            summary.totalCapitalIdr,
                          ),
                        ),
                        _SummaryItem(
                          label: 'Potensi Laba',
                          value: CurrencyFormatter.formatCompactRupiah(
                            summary.totalProfitPotentialIdr,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: provider.setInventorySearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Cari nama barang, kategori, catatan...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Color(0xFF9CA3AF),
                      ),
                      suffixIcon: provider.inventorySearchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                provider.setInventorySearchQuery('');
                              },
                              icon: const Icon(Icons.clear_rounded, size: 18),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF0B6E4F),
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: statuses.map((String status) {
                        final bool selected =
                            provider.selectedStockStatus == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(status),
                            selected: selected,
                            onSelected: (_) =>
                                provider.setSelectedStockStatus(status),
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateView(
                title: 'Belum Ada Data Barang',
                subtitle:
                    'Tidak ditemukan stok barang. Tambahkan stok baru atau reset pencarian.',
                icon: Icons.inventory_2_outlined,
                actionLabel: 'Reset Filter',
                onAction: () {
                  _searchController.clear();
                  provider.setInventorySearchQuery('');
                  provider.setSelectedStockStatus('Semua');
                },
              ),
            )
          else if (columns == 1)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  final MerchantItem item = items[index];
                  return MerchantItemCard(
                    item: item,
                    onEdit: () => _openEditScreen(context, item),
                    onDelete: () => _confirmAndDelete(context, item),
                    onIncrementStock: () =>
                        provider.adjustStockQuantity(item, 1),
                    onDecrementStock: () =>
                        provider.adjustStockQuantity(item, -1),
                  );
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 248,
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final MerchantItem item = items[index];
                    return MerchantItemCard(
                      item: item,
                      onEdit: () => _openEditScreen(context, item),
                      onDelete: () => _confirmAndDelete(context, item),
                      onIncrementStock: () =>
                          provider.adjustStockQuantity(item, 1),
                      onDecrementStock: () =>
                          provider.adjustStockQuantity(item, -1),
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D1A),
            ),
          ),
        ],
      ),
    );
  }
}
