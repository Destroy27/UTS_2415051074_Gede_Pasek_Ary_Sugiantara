import 'package:flutter/material.dart';

import '../core/currency_formatter.dart';
import '../models/merchant_item.dart';

/// Reusable Widget #5: Kartu Barang Stok Lapak Pedagang (Database Item).
///
/// Menampilkan status stok, harga modal vs harga jual, margin keuntungan,
/// catatan pedagang, serta aksi cepat (+1/-1 stok, Edit, dan Delete).
class MerchantItemCard extends StatelessWidget {
  const MerchantItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onIncrementStock,
    required this.onDecrementStock,
  });

  final MerchantItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onIncrementStock;
  final VoidCallback onDecrementStock;

  Color _statusColor(String status, ColorScheme colors) {
    switch (status) {
      case 'Stok Aman':
        return Colors.green.shade700;
      case 'Perlu Kulakan':
        return Colors.orange.shade800;
      case 'Habis':
        return colors.error;
      case 'Rencana Beli':
        return colors.tertiary;
      default:
        return colors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color badgeColor = _statusColor(item.restockStatus, colors);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: item.needsAttention
              ? badgeColor.withValues(alpha: 0.5)
              : colors.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          item.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.inventory_2_outlined,
                            color: colors.primary,
                          ),
                        )
                      : Icon(
                          Icons.inventory_2_outlined,
                          color: colors.primary,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              item.productTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.restockStatus,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: badgeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            item.category,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const Text('•'),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List<Widget>.generate(
                              5,
                              (int i) => Icon(
                                i < item.rating
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 14,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _PriceMetric(
                      label: 'Modal Beli',
                      value: CurrencyFormatter.formatRupiah(item.buyPrice),
                    ),
                  ),
                  Expanded(
                    child: _PriceMetric(
                      label: 'Harga Jual',
                      value: CurrencyFormatter.formatRupiah(item.sellPrice),
                      valueColor: colors.primary,
                    ),
                  ),
                  Expanded(
                    child: _PriceMetric(
                      label: 'Laba/Unit (${item.marginPercentage.toStringAsFixed(0)}%)',
                      value:
                          '+${CurrencyFormatter.formatRupiah(item.profitPerUnit)}',
                      valueColor: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (item.merchantNote.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.merchantNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 20),
            Row(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Kurangi 1 stok',
                        onPressed: item.stockQty > 0 ? onDecrementStock : null,
                        icon: const Icon(Icons.remove, size: 16),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          'Stok: ${item.stockQty}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Tambah 1 stok',
                        onPressed: onIncrementStock,
                        icon: const Icon(Icons.add, size: 16),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Hapus dari database',
                  onPressed: onDelete,
                  color: colors.error,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceMetric extends StatelessWidget {
  const _PriceMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
