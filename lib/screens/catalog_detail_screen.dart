import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/breakpoint.dart';
import '../core/currency_formatter.dart';
import '../models/merchant_item.dart';
import '../models/supplier_product.dart';
import '../providers/merchant_provider.dart';
import '../widgets/identity_header.dart';
import 'add_inventory_screen.dart';

/// Screen #3 (Detail): Halaman Detail Produk Grosir Supplier.
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
          content: Text('Produk "${result.productTitle}" masuk ke Stok Lapak!'),
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
          backgroundColor: const Color(0xFFF8FAF9),
          appBar: AppBar(
            title: const Text('Detail Produk'),
            actions: <Widget>[
              IconButton(
                tooltip: isBookmarked
                    ? 'Hapus Pantauan'
                    : 'Pantau Harga',
                onPressed: () {
                  provider.toggleBookmark(product.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        !isBookmarked
                            ? '"${product.title}" ditambahkan ke pantauan.'
                            : '"${product.title}" dihapus dari pantauan.',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: Icon(
                  isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isBookmarked ? const Color(0xFF0B6E4F) : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: LayoutBadge(category: category),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => provider.toggleBookmark(product.id),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(
                      isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isBookmarked ? 'Tersimpan' : 'Pantau',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openCreateWithProduct(context),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.add_business_rounded, size: 18),
                      label: Text(
                        'Masuk ke Stok Lapak',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    IdentityHeader(
                      subtitle: 'Detail Produk • SKU: ${product.sku} • ID #${product.id}',
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
                    _buildSimulationCard(
                      context,
                      product,
                      qty,
                      totalCapital,
                      totalRevenue,
                      totalProfit,
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
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: product.thumbnail.isNotEmpty
          ? Image.network(
              product.thumbnail,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: primaryColor,
              ),
            )
          : Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: primaryColor,
            ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    SupplierProduct product,
    bool isInInventory,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              _InfoChip(label: product.categoryLabel),
              _InfoChip(
                label: 'Rating ${product.rating.toStringAsFixed(1)}',
                icon: Icons.star_rounded,
                iconColor: Colors.amber.shade600,
              ),
              if (isInInventory)
                _InfoChip(
                  label: 'Di Lapak',
                  icon: Icons.check_circle_rounded,
                  iconColor: const Color(0xFF059669),
                  bgColor: const Color(0xFFECFDF5),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            product.title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1D1A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Brand: ${product.brand} • Min. Order: ${product.minimumOrderQuantity} unit',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Harga Modal',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.formatRupiah(product.wholesalePriceIdr),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0B6E4F),
                        ),
                      ),
                      Text(
                        '\$${product.priceUsd.toStringAsFixed(2)} (Diskon ${product.discountPercentage.toStringAsFixed(1)}%)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Saran Jual',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.formatRupiah(product.suggestedRetailPriceIdr),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF059669),
                        ),
                      ),
                      Text(
                        '+${CurrencyFormatter.formatRupiah(product.estimatedProfitPerUnit)} /unit',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF059669),
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
            'Deskripsi',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ketersediaan: ${product.stock} unit siap kirim',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: product.stock > 10
                  ? const Color(0xFF059669)
                  : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationCard(
    BuildContext context,
    SupplierProduct product,
    int qty,
    int totalCapital,
    int totalRevenue,
    int totalProfit,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.calculate_outlined, size: 18, color: Color(0xFF0B6E4F)),
              const SizedBox(width: 8),
              Text(
                'Simulasi Kulakan & Estimasi Keuntungan',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1D1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Geser slider untuk menghitung modal dan potensi keuntungan jika kulakan $qty unit.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          Slider(
            value: _simulatedQty,
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: const Color(0xFF0B6E4F),
            label: '$qty unit',
            onChanged: (double value) {
              setState(() => _simulatedQty = value);
            },
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Wrap(
              spacing: 20,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              children: <Widget>[
                _MetricTile(title: 'Jumlah', value: '$qty Unit'),
                _MetricTile(
                  title: 'Total Modal',
                  value: CurrencyFormatter.formatRupiah(totalCapital),
                ),
                _MetricTile(
                  title: 'Estimasi Omzet',
                  value: CurrencyFormatter.formatRupiah(totalRevenue),
                ),
                _MetricTile(
                  title: 'Estimasi Laba',
                  value: '+${CurrencyFormatter.formatRupiah(totalProfit)}',
                  highlight: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    this.icon,
    this.iconColor,
    this.bgColor,
  });

  final String label;
  final IconData? icon;
  final Color? iconColor;
  final Color? bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor ?? const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 13, color: iconColor ?? const Color(0xFF6B7280)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4B5563),
            ),
          ),
        ],
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
        Text(
          title,
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
            fontWeight: FontWeight.w700,
            color: highlight
                ? const Color(0xFF059669)
                : const Color(0xFF1A1D1A),
          ),
        ),
      ],
    );
  }
}
