import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/breakpoint.dart';
import '../core/currency_formatter.dart';
import '../models/merchant_item.dart';
import '../models/supplier_product.dart';
import '../providers/merchant_provider.dart';
import '../widgets/identity_header.dart';
import 'add_inventory_screen.dart';

/// Screen #3 (Detail): Halaman Detail Produk Grosir Supplier (Navigasi List → Detail).
///
/// Menerima objek [SupplierProduct] melalui constructor (passing data antar-screen),
/// menyediakan simulasi kulakan interaktif (Slider), toggle Bookmark (Shared State),
/// dan meneruskan produk ke halaman Form Create Database (`AddInventoryScreen`).
class CatalogDetailScreen extends StatefulWidget {
  const CatalogDetailScreen({super.key, required this.product});

  final SupplierProduct product;

  @override
  State<CatalogDetailScreen> createState() => _CatalogDetailScreenState();
}

class _CatalogDetailScreenState extends State<CatalogDetailScreen> {
  late double _simulatedQty;

  @override
  void initState() {
    super.initState();
    _simulatedQty = widget.product.minimumOrderQuantity.clamp(1, 50).toDouble();
  }

  Future<void> _openCreateWithProduct(BuildContext context) async {
    final MerchantProvider provider = context.read<MerchantProvider>();
    provider.selectDraftSupplierProduct(widget.product);

    final MerchantItem? result = await Navigator.of(context).push<MerchantItem>(
      MaterialPageRoute<MerchantItem>(
        builder: (_) => AddInventoryScreen(
          initialProduct: widget.product,
          isPushedRoute: true,
        ),
      ),
    );

    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Produk "${result.productTitle}" telah masuk ke Stok Lapak!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final SupplierProduct product = widget.product;
    final MerchantProvider provider = context.watch<MerchantProvider>();
    final bool isBookmarked = provider.isProductBookmarked(product.id);
    final bool isInInventory = provider.isInMerchantInventory(product.id);
    final int qty = _simulatedQty.round();
    final int totalCapital = product.wholesalePriceIdr * qty;
    final int totalRevenue = product.suggestedRetailPriceIdr * qty;
    final int totalProfit = totalRevenue - totalCapital;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final LayoutCategory category = layoutCategoryOf(constraints.maxWidth);
        final bool isWide = category != LayoutCategory.compact;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Produk Supplier'),
            actions: <Widget>[
              IconButton(
                tooltip: isBookmarked
                    ? 'Hapus dari Pantauan Harga'
                    : 'Tambah ke Pantauan Harga',
                onPressed: () {
                  provider.toggleBookmark(product.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        !isBookmarked
                            ? '"${product.title}" ditambahkan ke daftar pantauan harga.'
                            : '"${product.title}" dihapus dari daftar pantauan.',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: LayoutBadge(category: category),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => provider.toggleBookmark(product.id),
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    label: Text(isBookmarked ? 'Tersimpan' : 'Pantau Harga'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openCreateWithProduct(context),
                      icon: const Icon(Icons.add_business),
                      label: const Text('Masuk ke Stok Lapak (Database)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    IdentityHeader(
                      subtitle:
                          'Detail Produk REST API • SKU: ${product.sku} • ID #${product.id}',
                      dense: true,
                    ),
                    const SizedBox(height: 16),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            flex: 4,
                            child: _buildImageCard(context, product),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 6,
                            child: _buildInfoSection(
                              context,
                              product,
                              isInInventory,
                            ),
                          ),
                        ],
                      )
                    else ...<Widget>[
                      _buildImageCard(context, product),
                      const SizedBox(height: 16),
                      _buildInfoSection(context, product, isInInventory),
                    ],
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Icon(Icons.calculate_outlined),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Simulasi Kulakan & Estimasi Keuntungan Pedagang',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Geser slider untuk menghitung modal dan potensi keuntungan jika Anda kulakan sebanyak $qty unit:',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Slider(
                              value: _simulatedQty,
                              min: 1,
                              max: 100,
                              divisions: 99,
                              label: '$qty unit',
                              onChanged: (double value) {
                                setState(() => _simulatedQty = value);
                              },
                            ),
                            Wrap(
                              spacing: 20,
                              runSpacing: 12,
                              alignment: WrapAlignment.spaceBetween,
                              children: <Widget>[
                                _MetricTile(
                                  title: 'Jumlah Kulakan',
                                  value: '$qty Unit',
                                ),
                                _MetricTile(
                                  title: 'Total Modal Beli',
                                  value: CurrencyFormatter.formatRupiah(
                                    totalCapital,
                                  ),
                                ),
                                _MetricTile(
                                  title: 'Estimasi Omzet Jual',
                                  value: CurrencyFormatter.formatRupiah(
                                    totalRevenue,
                                  ),
                                ),
                                _MetricTile(
                                  title: 'Estimasi Laba Bersih',
                                  value:
                                      '+${CurrencyFormatter.formatRupiah(totalProfit)}',
                                  highlight: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageCard(BuildContext context, SupplierProduct product) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Container(
        height: 240,
        width: double.infinity,
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        padding: const EdgeInsets.all(16),
        child: product.thumbnail.isNotEmpty
            ? Image.network(
                product.thumbnail,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  Icons.local_shipping_outlined,
                  size: 72,
                  color: colors.primary,
                ),
              )
            : Icon(
                Icons.local_shipping_outlined,
                size: 72,
                color: colors.primary,
              ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    SupplierProduct product,
    bool isInInventory,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(
                  label: Text(product.categoryLabel),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  avatar: Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber.shade700,
                  ),
                  label: Text('Rating ${product.rating.toStringAsFixed(2)}'),
                  visualDensity: VisualDensity.compact,
                ),
                if (isInInventory)
                  Chip(
                    avatar: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green.shade700,
                    ),
                    label: const Text('Sudah Ada di Lapak'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              product.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Brand / Agen: ${product.brand} • Min. Order: ${product.minimumOrderQuantity} unit',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Harga Modal Grosir',
                          style: theme.textTheme.labelSmall,
                        ),
                        Text(
                          CurrencyFormatter.formatRupiah(
                            product.wholesalePriceIdr,
                          ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                        Text(
                          'Harga API: \$${product.priceUsd.toStringAsFixed(2)} (Diskon ${product.discountPercentage.toStringAsFixed(1)}%)',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Rekomendasi Harga Jual',
                          style: theme.textTheme.labelSmall,
                        ),
                        Text(
                          CurrencyFormatter.formatRupiah(
                            product.suggestedRetailPriceIdr,
                          ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        Text(
                          'Untung +${CurrencyFormatter.formatRupiah(product.estimatedProfitPerUnit)} / unit',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Deskripsi Barang Supplier',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              product.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Ketersediaan Gudang Supplier: ${product.stock} unit siap kirim',
              style: theme.textTheme.labelLarge?.copyWith(
                color: product.stock > 10
                    ? Colors.green.shade800
                    : Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    this.highlight = false,
  });

  final String title;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.labelSmall),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: highlight ? Colors.green.shade800 : null,
              ),
        ),
      ],
    );
  }
}
