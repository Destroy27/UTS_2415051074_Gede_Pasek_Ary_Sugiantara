import 'package:flutter/material.dart';

import '../core/currency_formatter.dart';
import '../models/supplier_product.dart';

/// Reusable Widget #6: Kartu Produk Katalog Grosir dari REST API.
class SupplierProductCard extends StatelessWidget {
  const SupplierProductCard({
    super.key,
    required this.product,
    required this.isBookmarked,
    required this.isInInventory,
    required this.onTapDetail,
    required this.onToggleBookmark,
    required this.onQuickAddInventory,
  });

  final SupplierProduct product;
  final bool isBookmarked;
  final bool isInInventory;
  final VoidCallback onTapDetail;
  final VoidCallback onToggleBookmark;
  final VoidCallback onQuickAddInventory;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: InkWell(
        onTap: onTapDetail,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: product.thumbnail.isNotEmpty
                        ? Image.network(
                            product.thumbnail,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.local_shipping_outlined,
                              color: colors.primary,
                              size: 28,
                            ),
                          )
                        : Icon(
                            Icons.local_shipping_outlined,
                            color: colors.primary,
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                product.categoryLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (product.discountPercentage > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Hemat ${product.discountPercentage.toStringAsFixed(0)}%',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${product.brand} • Stok Agen: ${product.stock} unit',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: isBookmarked
                        ? 'Hapus dari pantauan harga'
                        : 'Simpan ke pantauan harga (Shared State)',
                    onPressed: onToggleBookmark,
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? colors.primary : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Harga Modal Grosir',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatRupiah(
                              product.wholesalePriceIdr,
                            ),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
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
                            'Saran Jual (+Laba)',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${CurrencyFormatter.formatRupiah(product.suggestedRetailPriceIdr)} (+${CurrencyFormatter.formatRupiah(product.estimatedProfitPerUnit, withPrefix: false)})',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (isInInventory)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(
                        Icons.check_circle,
                        size: 15,
                        color: Colors.green.shade700,
                      ),
                      label: const Text(
                        'Ada di Lapak',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: onTapDetail,
                    child: const Text('Detail'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.tonalIcon(
                    onPressed: onQuickAddInventory,
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text('Kulakan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
