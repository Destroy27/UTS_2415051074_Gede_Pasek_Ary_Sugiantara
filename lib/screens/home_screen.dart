import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/breakpoint.dart';
import '../core/currency_formatter.dart';
import '../models/merchant_item.dart';
import '../models/merchant_summary.dart';
import '../models/supplier_product.dart';
import '../providers/merchant_provider.dart';
import '../widgets/identity_header.dart';
import '../widgets/summary_stat_card.dart';
import 'add_inventory_screen.dart';
import 'catalog_detail_screen.dart';
import 'edit_inventory_screen.dart';

/// Screen #1 (Home / Dashboard): Ringkasan bisnis pedagang UMKM, peringatan
/// stok menipis (Perlu Kulakan), serta rekomendasi produk grosir dari REST API.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onNavigateTab,
  });

  final ValueChanged<int> onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final MerchantProvider provider = context.watch<MerchantProvider>();
    final MerchantSummary summary = provider.summary;
    final List<MerchantItem> restockItems = provider.inventoryItems
        .where((MerchantItem item) => item.needsAttention)
        .take(4)
        .toList();
    final List<SupplierProduct> featuredCatalog =
        provider.catalogProducts.take(6).toList();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final LayoutCategory category = layoutCategoryOf(constraints.maxWidth);
        final int statCols = category == LayoutCategory.compact
            ? 2
            : (category == LayoutCategory.medium ? 2 : 4);
        final int catalogCols = gridColumnsFor(category);

        return Scaffold(
          appBar: AppBar(
            title: const Text('LapakPintar • Dashboard Pedagang'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Segarkan Semua Data',
                onPressed: () => provider.initializeData(),
                icon: const Icon(Icons.sync),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: LayoutBadge(category: category),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.initializeData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const IdentityHeader(),
                      const SizedBox(height: 16),
                      _buildHeroBanner(context, provider),
                      const SizedBox(height: 16),
                      Text(
                        'Ringkasan Keuangan & Stok Warung',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: statCols,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio:
                            category == LayoutCategory.compact ? 1.38 : 1.75,
                        children: <Widget>[
                          SummaryStatCard(
                            title: 'Total Modal Stok',
                            value: CurrencyFormatter.formatCompactRupiah(
                              summary.totalCapitalIdr,
                            ),
                            subtitle:
                                '${summary.totalSkuCount} jenis barang (${summary.totalUnitsInStock} unit)',
                            icon: Icons.account_balance_wallet_outlined,
                            onTap: () => onNavigateTab(2),
                          ),
                          SummaryStatCard(
                            title: 'Potensi Laba Bersih',
                            value:
                                '+${CurrencyFormatter.formatCompactRupiah(summary.totalProfitPotentialIdr)}',
                            subtitle:
                                'Rata-rata margin +${summary.averageMarginPercent.toStringAsFixed(1)}%',
                            icon: Icons.trending_up_rounded,
                            accentColor: Colors.green.shade700,
                            onTap: () => onNavigateTab(2),
                          ),
                          SummaryStatCard(
                            title: 'Perlu Kulakan',
                            value: '${summary.needsRestockCount} Barang',
                            subtitle: summary.needsRestockCount > 0
                                ? 'Segera belanja ke supplier'
                                : 'Seluruh stok warung aman',
                            icon: Icons.notification_important_outlined,
                            accentColor: Colors.orange.shade800,
                            onTap: () {
                              provider.setSelectedStockStatus('Perlu Kulakan');
                              onNavigateTab(2);
                            },
                          ),
                          SummaryStatCard(
                            title: 'Pantauan Grosir API',
                            value: '${provider.bookmarkCount} Produk',
                            subtitle:
                                'Dari ${provider.catalogProducts.length} katalog supplier',
                            icon: Icons.bookmark_added_outlined,
                            accentColor: Theme.of(context).colorScheme.tertiary,
                            onTap: () {
                              provider.setOnlyBookmarkedCatalog(true);
                              onNavigateTab(1);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildRestockSection(context, restockItems),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Rekomendasi Kulakan Grosir (REST API)',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Harga modal supplier terkini untuk stok warung Anda',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              provider.resetCatalogFilters();
                              onNavigateTab(1);
                            },
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: const Text('Lihat Semua'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (provider.isLoadingCatalog)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (featuredCatalog.isEmpty)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.cloud_off),
                            title: const Text('Katalog belum dimuat'),
                            trailing: TextButton(
                              onPressed: () => provider.loadCatalog(),
                              child: const Text('Muat Ulang'),
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: featuredCatalog.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: catalogCols,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            mainAxisExtent: 126,
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            final SupplierProduct product =
                                featuredCatalog[index];
                            return _FeaturedCatalogTile(product: product);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner(BuildContext context, MerchantProvider provider) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.verified_outlined,
                        size: 18, color: colors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Solusi Digital Pedagang & Warung UMKM',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Cek harga modal grosir dari REST API Supplier & kelola catatan stok serta keuntungan warung pada Database Supabase.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () => onNavigateTab(1),
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Cek Harga Grosir'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const AddInventoryScreen(isPushedRoute: true),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Catat Stok Baru'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestockSection(
    BuildContext context,
    List<MerchantItem> restockItems,
  ) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.assignment_late_outlined,
                  color: Colors.orange.shade800,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daftar Belanja / Barang Perlu Kulakan Segera',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigateTab(2),
                  child: const Text('Kelola Stok'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (restockItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Semua stok barang di lapak dalam kondisi aman! Tidak ada barang yang habis.',
                ),
              )
            else
              ...restockItems.map((MerchantItem item) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    foregroundColor: Colors.orange.shade900,
                    child: Text('${item.stockQty}'),
                  ),
                  title: Text(
                    item.productTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Status: ${item.restockStatus} • Modal: ${CurrencyFormatter.formatRupiah(item.buyPrice)}',
                  ),
                  trailing: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => EditInventoryScreen(item: item),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Update'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCatalogTile extends StatelessWidget {
  const _FeaturedCatalogTile({required this.product});

  final SupplierProduct product;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => CatalogDetailScreen(product: product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: product.thumbnail.isNotEmpty
                    ? Image.network(
                        product.thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.local_shipping_outlined,
                          color: colors.primary,
                        ),
                      )
                    : Icon(
                        Icons.local_shipping_outlined,
                        color: colors.primary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      product.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Modal: ${CurrencyFormatter.formatRupiah(product.wholesalePriceIdr)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Est. Laba +${CurrencyFormatter.formatRupiah(product.estimatedProfitPerUnit)}/unit',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.green.shade700,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
