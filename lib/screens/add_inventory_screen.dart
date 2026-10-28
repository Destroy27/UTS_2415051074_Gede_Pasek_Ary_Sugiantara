import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/breakpoint.dart';
import '../core/currency_formatter.dart';
import '../core/student_identity.dart';
import '../models/merchant_item.dart';
import '../models/supplier_product.dart';
import '../providers/merchant_provider.dart';
import '../widgets/identity_header.dart';

/// Screen #4 (Create/Add): Form Tambah Barang Dagangan & Catatan Kulakan ke Database.
///
/// Dapat dibuka melalui:
/// - Tab navigasi utama "Tambah Stok"
/// - Tombol "Masuk ke Stok Lapak" pada Detail Katalog Produk Supplier (passing data)
/// - FloatingActionButton pada halaman Stok Lapak.
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
          content: Text(
            'Mohon periksa kembali input form yang belum valid.',
          ),
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
          content: Text('Gagal menyimpan data ke database: $e'),
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
    final int previewProfitPerUnit = previewSell - previewBuy;
    final int previewTotalProfit = previewProfitPerUnit * previewStock;
    final int previewTotalCapital = previewBuy * previewStock;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final LayoutCategory category = layoutCategoryOf(constraints.maxWidth);
        final bool isWide = category != LayoutCategory.compact;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tambah Stok & Kulakan Lapak'),
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
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const IdentityHeader(
                      subtitle:
                          'Form CREATE Database: Catat stok barang baru & kalkulasi margin keuntungan',
                      dense: true,
                    ),
                    const SizedBox(height: 14),
                    if (_linkedProductId > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer
                              .withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.auto_awesome, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Data produk diambil dari Katalog REST API (ID #$_linkedProductId). Anda bebas menyesuaikan harga jual & stok warung.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            TextButton(
                              onPressed: _resetForm,
                              child: const Text('Input Manual'),
                            ),
                          ],
                        ),
                      ),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '1. Informasi Barang Dagangan',
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
                                      hintText:
                                          'Contoh: Beras Ramos 5Kg / Minyak Goreng 1L',
                                      prefixIcon:
                                          Icon(Icons.shopping_bag_outlined),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (String? value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Nama barang wajib diisi';
                                      }
                                      if (value.trim().length < 3) {
                                        return 'Nama barang minimal 3 karakter';
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
                          ),
                          const SizedBox(height: 14),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '2. Harga Modal, Harga Jual & Jumlah Stok',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 14),
                                  if (isWide)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        'Bantu Hitung Harga Jual:',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium,
                                      ),
                                      ActionChip(
                                        label: const Text('+15% Laba'),
                                        onPressed: () => _applyQuickMargin(15),
                                      ),
                                      ActionChip(
                                        label: const Text('+25% Laba'),
                                        onPressed: () => _applyQuickMargin(25),
                                      ),
                                      ActionChip(
                                        label: const Text('+35% Laba'),
                                        onPressed: () => _applyQuickMargin(35),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '3. Rating Perputaran Barang & Catatan Pedagang',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: <Widget>[
                                      const Text('Tingkat Laris (1-5): '),
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
                                          'Catatan Pedagang / Nama Agen Grosir *',
                                      hintText:
                                          'Contoh: Beli di Agen Makmur Pasar Anyar, diskon jika ambil 2 dus.',
                                      prefixIcon: Icon(Icons.edit_note),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (String? value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Catatan pedagang wajib diisi';
                                      }
                                      if (value.trim().length < 5) {
                                        return 'Catatan minimal 5 karakter';
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
                                  .primaryContainer
                                  .withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Wrap(
                              spacing: 20,
                              runSpacing: 10,
                              alignment: WrapAlignment.spaceBetween,
                              children: <Widget>[
                                _buildCalcItem(
                                  'Laba / Unit',
                                  CurrencyFormatter.formatRupiah(
                                    previewProfitPerUnit,
                                  ),
                                  isPositive: previewProfitPerUnit >= 0,
                                ),
                                _buildCalcItem(
                                  'Total Modal Stok',
                                  CurrencyFormatter.formatRupiah(
                                    previewTotalCapital,
                                  ),
                                ),
                                _buildCalcItem(
                                  'Total Potensi Laba',
                                  CurrencyFormatter.formatRupiah(
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
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reset'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: provider.isSubmitting
                                      ? null
                                      : _submitForm,
                                  icon: provider.isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: Text(
                                    provider.isSubmitting
                                        ? 'Menyimpan Data...'
                                        : 'Simpan ke Stok Lapak (Database)',
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
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryField() {
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

  Widget _buildStatusField() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedStatus,
      decoration: const InputDecoration(
        labelText: 'Status Stok / Kulakan',
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

  Widget _buildBuyPriceField() {
    return TextFormField(
      controller: _buyPriceController,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(
        labelText: 'Harga Beli / Modal (Rp) *',
        hintText: 'Contoh: 15000',
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

  Widget _buildSellPriceField() {
    return TextFormField(
      controller: _sellPriceController,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(
        labelText: 'Harga Jual Warung (Rp) *',
        hintText: 'Contoh: 18000',
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
          return 'Harga jual < modal (rugi)';
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
        hintText: 'Contoh: 24',
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

  Widget _buildCalcItem(
    String label,
    String value, {
    bool isPositive = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green.shade800 : Colors.red.shade700,
              ),
        ),
      ],
    );
  }
}
