import 'package:flutter/material.dart';
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

/// Screen #6 (Saved / Inventory List): Menampilkan & mengelola data stok barang
/// dagangan dari Database Supabase (Read, Quick Update, Navigate to Edit, Delete
/// dengan Confirmation Dialog).
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
          icon: Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(dialogContext).colorScheme.error,
            size: 36,
          ),
          title: const Text('Konfirmasi Hapus Barang'),
          content: Text(
            'Apakah Anda yakin ingin menghapus "${item.productTitle}" (Stok: ${item.stockQty} unit) dari database lapak?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Ya, Hapus'),
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
            'Barang "${item.productTitle}" telah dihapus dari database.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus data: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
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
          appBar: AppBar(
            title: const Text('Stok Lapak & Catatan Kulakan'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Muat Ulang Database',
                onPressed: () => provider.loadInventory(),
                icon: const Icon(Icons.refresh),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opsi Pengujian State Database',
                onSelected: (String value) {
                  if (value == 'simulate_error') {
                    provider.loadInventory(simulateError: true);
                  } else if (value == 'reload') {
                    provider.loadInventory();
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'reload',
                    child: ListTile(
                      leading: Icon(Icons.sync),
                      title: Text('Sinkronisasi Database'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'simulate_error',
                    child: ListTile(
                      leading: Icon(Icons.bug_report_outlined),
                      title: Text('Simulasi Error Database'),
                      contentPadding: EdgeInsets.zero,
                    ),
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
            icon: const Icon(Icons.add),
            label: const Text('Barang Baru'),
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
        message: 'Memuat data inventaris barang pedagang dari database...',
      );
    }

    if (provider.inventoryError != null) {
      return ErrorStateView(
        title: 'Gagal Memuat Database Inventaris',
        message: provider.inventoryError!,
        onRetry: () => provider.loadInventory(),
      );
    }

    final List<String> statuses = <String>[
      'Semua',
      ...MerchantItem.validStatuses,
    ];

    return RefreshIndicator(
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
                        ? 'Database Aktif: Supabase PostgreSQL (Tabel merchant_inventory)'
                        : 'Database Aktif: Mode Lokal Otomatis (Siap dihubungkan ke Supabase)',
                    dense: true,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Wrap(
                      spacing: 18,
                      runSpacing: 10,
                      alignment: WrapAlignment.spaceBetween,
                      children: <Widget>[
                        _SummaryItem(
                          label: 'Jenis Barang',
                          value: '${summary.totalSkuCount} SKU',
                        ),
                        _SummaryItem(
                          label: 'Total Unit Stok',
                          value: '${summary.totalUnitsInStock} Unit',
                        ),
                        _SummaryItem(
                          label: 'Total Modal',
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
                      hintText:
                          'Cari nama barang, kategori, atau catatan agen...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: provider.inventorySearchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                provider.setInventorySearchQuery('');
                              },
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
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
                title: 'Belum Ada Data Barang yang Cocok',
                subtitle:
                    'Tidak ditemukan stok barang untuk filter ini. Tambahkan stok baru atau reset pencarian Anda.',
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
                  mainAxisExtent: 256,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
