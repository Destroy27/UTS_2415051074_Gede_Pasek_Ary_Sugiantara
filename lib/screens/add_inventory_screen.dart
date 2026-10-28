import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/breakpoint.dart';
import '../core/currency_formatter.dart';
import '../core/student_identity.dart';
import '../models/merchant_item.dart';
import '../models/supplier_product.dart';
import '../providers/merchant_provider.dart';
import '../widgets/identity_header.dart';

/// Screen #4 (Create/Add): Form Tambah Barang Dagangan & Catatan Kulakan.
class AddInventoryScreen extends StatefulWidget {
  const AddInventoryScreen({
    super.key,
    this.initialProduct,
    this.onSavedJumpToInventory,
    this.isPushedRoute = false,
  });

  final SupplierProduct? initialProduct;
  final VoidCallback? onSavedJumpToInventory;
  final bool isPushedRoute;

  @override
  State<AddInventoryScreen> createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends State<AddInventoryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _buyPriceController;
  late final TextEditingController _sellPriceController;
  late final TextEditingController _stockQtyController;
  late final TextEditingController _noteController;

  String _selectedCategory = MerchantItem.standardCategories.first;
  String _selectedStatus = MerchantItem.validStatuses.first;
  int _selectedRating = 5;
  int _linkedProductId = 0;
  String _thumbnailUrl = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _buyPriceController = TextEditingController();
    _sellPriceController = TextEditingController();
    _stockQtyController = TextEditingController(text: '10');
    _noteController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final SupplierProduct? source = widget.initialProduct ??
          context.read<MerchantProvider>().draftSupplierProduct;
      if (source != null) {
        _applySupplierProduct(source);
      }
    });
  }

  void _applySupplierProduct(SupplierProduct product) {
    setState(() {
      _linkedProductId = product.id;
      _thumbnailUrl = product.thumbnail;
      _titleController.text = product.title;
      _buyPriceController.text = product.wholesalePriceIdr.toString();
      _sellPriceController.text = product.suggestedRetailPriceIdr.toString();
      _stockQtyController.text =
          product.minimumOrderQuantity > 1 ? '${product.minimumOrderQuantity}' : '12';
      _noteController.text =
          'Supplier: ${product.brand} (SKU: ${product.sku}). Diskon grosir ${product.discountPercentage.toStringAsFixed(1)}%.';
      if (MerchantItem.standardCategories.contains(product.categoryLabel)) {
        _selectedCategory = product.categoryLabel;
      } else {
        _selectedCategory = MerchantItem.standardCategories.first;
      }
      _selectedStatus = 'Stok Aman';
      _selectedRating = product.rating.round().clamp(1, 5);
    });
  }

  void _resetForm() {
    context.read<MerchantProvider>().selectDraftSupplierProduct(null);
    _formKey.currentState?.reset();
    setState(() {
      _linkedProductId = 0;
      _thumbnailUrl = '';
      _titleController.clear();
      _buyPriceController.clear();
      _sellPriceController.clear();
      _stockQtyController.text = '10';
      _noteController.clear();
      _selectedCategory = MerchantItem.standardCategories.first;
      _selectedStatus = MerchantItem.validStatuses.first;
      _selectedRating = 5;
    });
  }

  void _applyQuickMargin(double marginPercent) {
    final int? buy = int.tryParse(_buyPriceController.text.trim());
    if (buy == null || buy <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan Harga Beli (Modal) terlebih dahulu.'),
        ),
      );
      return;
    }
    final int calculated =
        (((buy * (1 + marginPercent / 100)) / 500).round() * 500);
    setState(() {
      _sellPriceController.text = calculated.toString();
    });
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon periksa kembali input form yang belum valid.'),
        ),
      );
      return;
    }

    final MerchantProvider provider = context.read<MerchantProvider>();
    if (provider.isSubmitting) return;

    final int buyPrice = int.parse(_buyPriceController.text.trim());
    final int sellPrice = int.parse(_sellPriceController.text.trim());
    final int stockQty = int.parse(_stockQtyController.text.trim());

    final MerchantItem newItem = MerchantItem(
      studentId: studentId,
      productId: _linkedProductId,
      productTitle: _titleController.text.trim(),
      category: _selectedCategory,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      stockQty: stockQty,
      restockStatus: stockQty == 0 ? 'Habis' : _selectedStatus,
      merchantNote: _noteController.text.trim(),
      rating: _selectedRating,
      thumbnailUrl: _thumbnailUrl,
    );

    try {
      final MerchantItem created = await provider.createItem(newItem);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berhasil menyimpan "${created.productTitle}" ke stok lapak!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (widget.isPushedRoute) {
        Navigator.of(context).pop(created);
      } else {
        _resetForm();
        widget.onSavedJumpToInventory?.call();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan data: $e'),
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
    final int previewProfitPerUnit = previewSell - previewBuy;
    final int previewTotalProfit = previewProfitPerUnit * previewStock;
    final int previewTotalCapital = previewBuy * previewStock;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final LayoutCategory category = layoutCategoryOf(constraints.maxWidth);
        final bool isWide = category != LayoutCategory.compact;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF9),
          appBar: AppBar(
            title: const Text('Tambah Stok'),
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
                constraints: const BoxConstraints(maxWidth: 900),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const IdentityHeader(
                        subtitle:
                            'Form Create Database: Catat stok barang & kalkulasi margin',
                        dense: true,
                      ),
                      const SizedBox(height: 14),
                      if (_linkedProductId > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF0B6E4F).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.auto_awesome_rounded,
                                size: 18,
                                color: Color(0xFF0B6E4F),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Data produk dari Katalog REST API (ID #$_linkedProductId). Sesuaikan harga jual & stok warung.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _resetForm,
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF6B7280),
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 30),
                                ),
                                child: Text(
                                  'Input Manual',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      _buildCard(
                        title: 'Informasi Barang',
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Barang *',
                                hintText: 'Contoh: Beras Ramos 5Kg',
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
                                  Expanded(child: _buildCategoryField()),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildStatusField()),
                                ],
                              )
                            else ...<Widget>[
                              _buildCategoryField(),
                              const SizedBox(height: 14),
                              _buildStatusField(),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildCard(
                        title: 'Harga & Stok',
                        child: Column(
                          children: <Widget>[
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(child: _buildBuyPriceField()),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildSellPriceField()),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildStockQtyField()),
                                ],
                              )
                            else ...<Widget>[
                              _buildBuyPriceField(),
                              const SizedBox(height: 14),
                              _buildSellPriceField(),
                              const SizedBox(height: 14),
                              _buildStockQtyField(),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: <Widget>[
                                Text(
                                  'Bantu Hitung:',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                _QuickMarginChip(
                                  label: '+15%',
                                  onPressed: () => _applyQuickMargin(15),
                                ),
                                _QuickMarginChip(
                                  label: '+25%',
                                  onPressed: () => _applyQuickMargin(25),
                                ),
                                _QuickMarginChip(
                                  label: '+35%',
                                  onPressed: () => _applyQuickMargin(35),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildCard(
                        title: 'Rating & Catatan',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text(
                                  'Tingkat Laris:',
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
                                      setState(() {
                                        _selectedRating = star;
                                      });
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
                                labelText: 'Catatan Pedagang / Agen Supplier *',
                                hintText:
                                    'Contoh: Beli di Agen Makmur Pasar Anyar, diskon jika ambil 2 dus.',
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
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Wrap(
                          spacing: 24,
                          runSpacing: 10,
                          alignment: WrapAlignment.spaceBetween,
                          children: <Widget>[
                            _CalcItem(
                              label: 'Laba / Unit',
                              value: CurrencyFormatter.formatRupiah(
                                previewProfitPerUnit,
                              ),
                              isPositive: previewProfitPerUnit >= 0,
                            ),
                            _CalcItem(
                              label: 'Total Modal',
                              value: CurrencyFormatter.formatRupiah(
                                previewTotalCapital,
                              ),
                            ),
                            _CalcItem(
                              label: 'Total Potensi Laba',
                              value: CurrencyFormatter.formatRupiah(
                                previewTotalProfit,
                              ),
                              isPositive: previewTotalProfit >= 0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed:
                                provider.isSubmitting ? null : _resetForm,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(
                              'Reset',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: provider.isSubmitting
                                  ? null
                                  : _submitForm,
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
                                  : const Icon(Icons.save_outlined, size: 18),
                              label: Text(
                                provider.isSubmitting
                                    ? 'Menyimpan...'
                                    : 'Simpan ke Database',
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

  Widget _buildCategoryField() {
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

  Widget _buildStatusField() {
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

  Widget _buildBuyPriceField() {
    return TextFormField(
      controller: _buyPriceController,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(
        labelText: 'Harga Beli / Modal (Rp) *',
        hintText: '15000',
        prefixIcon: Icon(Icons.payments_outlined, size: 20),
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

  Widget _buildSellPriceField() {
    return TextFormField(
      controller: _sellPriceController,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(
        labelText: 'Harga Jual (Rp) *',
        hintText: '18000',
        prefixIcon: Icon(Icons.sell_outlined, size: 20),
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

  Widget _buildStockQtyField() {
    return TextFormField(
      controller: _stockQtyController,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(
        labelText: 'Jumlah Stok (Unit) *',
        hintText: '24',
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

class _QuickMarginChip extends StatelessWidget {
  const _QuickMarginChip({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      backgroundColor: const Color(0xFFF3F4F6),
      side: const BorderSide(color: Color(0xFFE5E7EB)),
    );
  }
}

class _CalcItem extends StatelessWidget {
  const _CalcItem({
    required this.label,
    required this.value,
    this.isPositive = true,
  });

  final String label;
  final String value;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    return Column(
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
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isPositive
                ? const Color(0xFF059669)
                : const Color(0xFFDC2626),
          ),
        ),
      ],
    );
  }
}
