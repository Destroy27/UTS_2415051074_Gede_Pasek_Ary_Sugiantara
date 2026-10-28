import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/breakpoint.dart';
import '../core/currency_formatter.dart';
import '../models/merchant_item.dart';
import '../providers/merchant_provider.dart';
import '../widgets/identity_header.dart';

/// Screen #5 (Edit): Form Edit Data Stok Barang & Catatan Pedagang.
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
          content: Text('Perubahan "${updatedItem.productTitle}" berhasil disimpan!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(updatedItem);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui: $e'),
          backgroundColor: const Color(0xFFDC2626),
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
          backgroundColor: const Color(0xFFF8FAF9),
          appBar: AppBar(
            title: const Text('Edit Stok'),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: LayoutBadge(category: category),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      IdentityHeader(
                        subtitle: 'Form Update Database • ID #${widget.item.id ?? "-"}',
                        dense: true,
                      ),
                      const SizedBox(height: 16),
                      _buildCard(
                        title: 'Perbarui Data Barang',
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Barang *',
                                prefixIcon: Icon(Icons.shopping_bag_outlined, size: 20),
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
                                Text(
                                  'Rating:',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ...List<Widget>.generate(5, (int idx) {
                                  final int star = idx + 1;
                                  return IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      setState(() => _selectedRating = star);
                                    },
                                    icon: Icon(
                                      star <= _selectedRating
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: Colors.amber.shade600,
                                      size: 22,
                                    ),
                                  );
                                }),
                                Text(
                                  '($_selectedRating/5)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _noteController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Catatan Pedagang / Agen *',
                                prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
                              ),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Catatan wajib diisi';
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
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Wrap(
                          spacing: 24,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Laba/Unit: ${CurrencyFormatter.formatRupiah(profitUnit)}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF059669),
                              ),
                            ),
                            Text(
                              'Potensi Total Laba: ${CurrencyFormatter.formatRupiah(profitTotal)}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF059669),
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
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: Text(
                              'Batal',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed:
                                  provider.isSubmitting ? null : _saveChanges,
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: provider.isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline_rounded, size: 18),
                              label: Text(
                                provider.isSubmitting
                                    ? 'Menyimpan...'
                                    : 'Simpan Perubahan',
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

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D1A),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Kategori',
        prefixIcon: Icon(Icons.category_outlined, size: 20),
      ),
      items: MerchantItem.standardCategories
          .map(
            (String cat) => DropdownMenuItem<String>(
              value: cat,
              child: Text(cat, style: GoogleFonts.inter(fontSize: 13)),
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
        prefixIcon: Icon(Icons.inventory_outlined, size: 20),
      ),
      items: MerchantItem.validStatuses
          .map(
            (String status) => DropdownMenuItem<String>(
              value: status,
              child: Text(status, style: GoogleFonts.inter(fontSize: 13)),
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
        labelText: 'Harga Beli (Rp) *',
        prefixIcon: Icon(Icons.payments_outlined, size: 20),
      ),
      validator: (String? value) {
        final int? parsed = int.tryParse(value?.trim() ?? '');
        if (parsed == null || parsed <= 0) {
          return 'Angka > 0';
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
        labelText: 'Harga Jual (Rp) *',
        prefixIcon: Icon(Icons.sell_outlined, size: 20),
      ),
      validator: (String? value) {
        final int? sell = int.tryParse(value?.trim() ?? '');
        final int? buy = int.tryParse(_buyPriceController.text.trim());
        if (sell == null || sell <= 0) {
          return 'Angka > 0';
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
        prefixIcon: Icon(Icons.numbers, size: 20),
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
