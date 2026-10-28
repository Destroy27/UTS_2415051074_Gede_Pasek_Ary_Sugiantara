import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/breakpoint.dart';
import '../core/currency_formatter.dart';
import '../models/merchant_item.dart';
import '../providers/merchant_provider.dart';
import '../widgets/identity_header.dart';

/// Screen #5 (Edit): Form Edit Data Stok Barang & Catatan Pedagang pada Database.
///
/// Menerima objek [MerchantItem] melalui constructor (passing data antar-screen),
/// melakukan validasi input, dan menyimpan perubahan melalui `provider.updateItem`.
class EditInventoryScreen extends StatefulWidget {
  const EditInventoryScreen({super.key, required this.item});

  final MerchantItem item;

  @override
  State<EditInventoryScreen> createState() => _EditInventoryScreenState();
}

class _EditInventoryScreenState extends State<EditInventoryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _buyPriceController;
  late final TextEditingController _sellPriceController;
  late final TextEditingController _stockQtyController;
  late final TextEditingController _noteController;

  late String _selectedCategory;
  late String _selectedStatus;
  late int _selectedRating;

  @override
  void initState() {
    super.initState();
    final MerchantItem item = widget.item;
    _titleController = TextEditingController(text: item.productTitle);
    _buyPriceController = TextEditingController(text: item.buyPrice.toString());
    _sellPriceController =
        TextEditingController(text: item.sellPrice.toString());
    _stockQtyController = TextEditingController(text: item.stockQty.toString());
    _noteController = TextEditingController(text: item.merchantNote);

    _selectedCategory =
        MerchantItem.standardCategories.contains(item.category)
            ? item.category
            : MerchantItem.standardCategories.first;
    _selectedStatus =
        MerchantItem.validStatuses.contains(item.restockStatus)
            ? item.restockStatus
            : MerchantItem.validStatuses.first;
    _selectedRating = item.rating.clamp(1, 5);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _stockQtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon periksa kembali input form yang belum valid.'),
        ),
      );
      return;
    }

    final int? id = widget.item.id;
    if (id == null) return;

    final MerchantProvider provider = context.read<MerchantProvider>();
    if (provider.isSubmitting) return;

    final int buyPrice = int.parse(_buyPriceController.text.trim());
    final int sellPrice = int.parse(_sellPriceController.text.trim());
    final int stockQty = int.parse(_stockQtyController.text.trim());

    final MerchantItem updatedItem = widget.item.copyWith(
      productTitle: _titleController.text.trim(),
      category: _selectedCategory,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      stockQty: stockQty,
      restockStatus: stockQty == 0 ? 'Habis' : _selectedStatus,
      merchantNote: _noteController.text.trim(),
      rating: _selectedRating,
    );

    try {
      await provider.updateItem(id, updatedItem);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Perubahan "${updatedItem.productTitle}" berhasil disimpan!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(updatedItem);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui data: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final MerchantProvider provider = context.watch<MerchantProvider>();
    final int previewBuy = int.tryParse(_buyPriceController.text.trim()) ?? 0;
    final int previewSell = int.tryParse(_sellPriceController.text.trim()) ?? 0;
    final int previewStock = int.tryParse(_stockQtyController.text.trim()) ?? 0;
    final int profitUnit = previewSell - previewBuy;
    final int profitTotal = profitUnit * previewStock;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final LayoutCategory category = layoutCategoryOf(constraints.maxWidth);
        final bool isWide = category != LayoutCategory.compact;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Stok & Catatan Barang'),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: LayoutBadge(category: category),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      IdentityHeader(
                        subtitle:
                            'Form UPDATE Database • ID Barang #${widget.item.id ?? "-"}',
                        dense: true,
                      ),
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
                              Text(
                                'Perbarui Data Barang Dagangan',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Nama Barang Dagangan *',
                                  prefixIcon:
                                      Icon(Icons.shopping_bag_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (String? value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Nama barang wajib diisi';
                                  }
                                  if (value.trim().length < 3) {
                                    return 'Minimal 3 karakter';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              if (isWide)
                                Row(
                                  children: <Widget>[
                                    Expanded(child: _buildCategoryDropdown()),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildStatusDropdown()),
                                  ],
                                )
                              else ...<Widget>[
                                _buildCategoryDropdown(),
                                const SizedBox(height: 14),
                                _buildStatusDropdown(),
                              ],
                              const SizedBox(height: 14),
                              if (isWide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(child: _buildBuyField()),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildSellField()),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildStockField()),
                                  ],
                                )
                              else ...<Widget>[
                                _buildBuyField(),
                                const SizedBox(height: 14),
                                _buildSellField(),
                                const SizedBox(height: 14),
                                _buildStockField(),
                              ],
                              const SizedBox(height: 14),
                              Row(
                                children: <Widget>[
                                  const Text('Rating Laris (1-5): '),
                                  ...List<Widget>.generate(5, (int idx) {
                                    final int star = idx + 1;
                                    return IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        setState(() => _selectedRating = star);
                                      },
                                      icon: Icon(
                                        star <= _selectedRating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber.shade700,
                                      ),
                                    );
                                  }),
                                  Text(
                                    '($_selectedRating/5)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _noteController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText:
                                      'Catatan Pedagang / Info Agen Supplier *',
                                  prefixIcon: Icon(Icons.edit_note),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (String? value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Catatan pedagang wajib diisi';
                                  }
                                  if (value.trim().length < 5) {
                                    return 'Minimal 5 karakter';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer
                              .withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Laba/Unit: ${CurrencyFormatter.formatRupiah(profitUnit)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Potensi Total Laba: ${CurrencyFormatter.formatRupiah(profitTotal)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: provider.isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            label: const Text('Batal'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed:
                                  provider.isSubmitting ? null : _saveChanges,
                              icon: provider.isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(
                                provider.isSubmitting
                                    ? 'Menyimpan...'
                                    : 'Simpan Perubahan (UPDATE)',
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Kategori Barang',
        prefixIcon: Icon(Icons.category_outlined),
        border: OutlineInputBorder(),
      ),
      items: MerchantItem.standardCategories
          .map(
            (String cat) => DropdownMenuItem<String>(
              value: cat,
              child: Text(cat),
            ),
          )
          .toList(),
      onChanged: (String? value) {
        if (value != null) {
          setState(() => _selectedCategory = value);
        }
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedStatus,
      decoration: const InputDecoration(
        labelText: 'Status Stok',
        prefixIcon: Icon(Icons.inventory_outlined),
        border: OutlineInputBorder(),
      ),
      items: MerchantItem.validStatuses
          .map(
            (String status) => DropdownMenuItem<String>(
              value: status,
              child: Text(status),
            ),
          )
          .toList(),
      onChanged: (String? value) {
        if (value != null) {
          setState(() => _selectedStatus = value);
        }
      },
    );
  }

  Widget _buildBuyField() {
    return TextFormField(
      controller: _buyPriceController,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(
        labelText: 'Harga Beli Modal (Rp) *',
        prefixIcon: Icon(Icons.payments_outlined),
        border: OutlineInputBorder(),
      ),
      validator: (String? value) {
        final int? parsed = int.tryParse(value?.trim() ?? '');
        if (parsed == null || parsed <= 0) {
          return 'Masukkan angka > 0';
        }
        return null;
      },
    );
  }

  Widget _buildSellField() {
    return TextFormField(
      controller: _sellPriceController,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(
        labelText: 'Harga Jual Warung (Rp) *',
        prefixIcon: Icon(Icons.sell_outlined),
        border: OutlineInputBorder(),
      ),
      validator: (String? value) {
        final int? sell = int.tryParse(value?.trim() ?? '');
        final int? buy = int.tryParse(_buyPriceController.text.trim());
        if (sell == null || sell <= 0) {
          return 'Masukkan angka > 0';
        }
        if (buy != null && sell < buy) {
          return 'Harga jual < modal';
        }
        return null;
      },
    );
  }

  Widget _buildStockField() {
    return TextFormField(
      controller: _stockQtyController,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(
        labelText: 'Jumlah Stok (Unit) *',
        prefixIcon: Icon(Icons.numbers),
        border: OutlineInputBorder(),
      ),
      validator: (String? value) {
        final int? qty = int.tryParse(value?.trim() ?? '');
        if (qty == null || qty < 0) {
          return 'Stok minimal 0';
        }
        return null;
      },
    );
  }
}
