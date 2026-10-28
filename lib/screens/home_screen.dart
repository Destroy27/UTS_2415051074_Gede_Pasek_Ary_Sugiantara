import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

/// Screen #1 (Home / Dashboard): Ringkasan bisnis pedagang UMKM.
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
        final int statCols = category == LayoutCategory.compact ? 2 : 4;
        final int catalogCols = gridColumnsFor(category);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF9),
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Segarkan Data',
                onPressed: () => provider.initializeData(),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                color: const Color(0xFF6B7280),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: LayoutBadge(category: category),
              ),
            ],
          ),
          body: RefreshIndicator(
            color: const Color(0xFF0B6E4F),
            onRefresh: () => provider.initializeData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const IdentityHeader(),
                      const SizedBox(height: 16),
                      _buildHeroBanner(context, provider),
                      const SizedBox(height: 24),
                      Text(
                        'Ringkasan Keuangan & Stok',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1D1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: statCols,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio:
                            category == LayoutCategory.compact ? 1.35 : 1.75,
                        children: <Widget>[
                          SummaryStatCard(
                            title: 'Total Modal Stok',
                            value: CurrencyFormatter.formatCompactRupiah(
                              summary.totalCapitalIdr,
                            ),
                            subtitle:
                                '${summary.totalSkuCount} jenis • ${summary.totalUnitsInStock} unit',
                            icon: Icons.account_balance_wallet_outlined,
                            onTap: () => onNavigateTab(2),
                          ),
                          SummaryStatCard(
                            title: 'Potensi Laba',
                            value:
                                '+${CurrencyFormatter.formatCompactRupiah(summary.totalProfitPotentialIdr)}',
                            subtitle:
                                'Margin rata-rata ${summary.averageMarginPercent.toStringAsFixed(1)}%',
                            icon: Icons.trending_up_rounded,
                            accentColor: const Color(0xFF059669),
                            onTap: () => onNavigateTab(2),
                          ),
                          SummaryStatCard(
                            title: 'Perlu Kulakan',
                            value: '${summary.needsRestockCount} Barang',
                            subtitle: summary.needsRestockCount > 0
                                ? 'Segera belanja ke supplier'
                                : 'Semua stok aman',
                            icon: Icons.notification_important_outlined,
                            accentColor: Colors.orange.shade700,
                            onTap: () {
                              provider.setSelectedStockStatus('Perlu Kulakan');
                              onNavigateTab(2);
                            },
                          ),
                          SummaryStatCard(
                            title: 'Pantauan Grosir',
                            value: '${provider.bookmarkCount} Produk',
                            subtitle:
                                'Dari ${provider.catalogProducts.length} katalog',
                            icon: Icons.bookmark_added_outlined,
                            accentColor: const Color(0xFF2563EB),
                            onTap: () {
                              provider.setOnlyBookmarkedCatalog(true);
                              onNavigateTab(1);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildRestockSection(context, restockItems, provider),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Rekomendasi Kulakan',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1D1A),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              provider.resetCatalogFilters();
                              onNavigateTab(1);
                            },
                            child: Text(
                              'Lihat Semua →',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF0B6E4F),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (provider.isLoadingCatalog)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          ),
                        )
                      else if (featuredCatalog.isEmpty)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.cloud_off_outlined),
                            title: Text(
                              'Katalog belum dimuat',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
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
                            mainAxisExtent: 84,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B6E4F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'LapakPintar',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cek harga modal grosir dari REST API & kelola stok warung pada database Supabase.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    _HeroButton(
                      label: 'Cek Harga Grosir',
                      icon: Icons.local_shipping_outlined,
                      isPrimary: false,
                      onPressed: () => onNavigateTab(1),
                    ),
                    const SizedBox(width: 10),
                    _HeroButton(
                      label: 'Catat Stok Baru',
                      icon: Icons.add,
                      isPrimary: true,
                      onPressed: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const AddInventoryScreen(isPushedRoute: true),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestockSection(
    BuildContext context,
    List<MerchantItem> restockItems,
    MerchantProvider provider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.assignment_late_outlined,
                    size: 18,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Daftar Belanja / Perlu Kulakan',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1D1A),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigateTab(2),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0B6E4F),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                  child: Text(
                    'Kelola →',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (restockItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Semua stok barang dalam kondisi aman.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              )
            else
              ...restockItems.map((MerchantItem item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${item.stockQty}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.productTitle,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1A1D1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item.restockStatus,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => EditInventoryScreen(item: item),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0B6E4F),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 30),
                        ),
                        child: Text(
                          'Update',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isPrimary ? Colors.white : Colors.transparent,
        foregroundColor: isPrimary ? const Color(0xFF0B6E4F) : Colors.white,
        side: BorderSide(
          color: isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.4),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
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
      child: InkWell(
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => CatalogDetailScreen(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
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
                          Icons.inventory_2_outlined,
                          color: colors.primary,
                          size: 20,
                        ),
                      )
                    : Icon(
                        Icons.inventory_2_outlined,
                        color: colors.primary,
                        size: 20,
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
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1D1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatRupiah(product.wholesalePriceIdr),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                    Text(
                      '+${CurrencyFormatter.formatRupiah(product.estimatedProfitPerUnit)} /unit',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
