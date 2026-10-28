import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/breakpoint.dart';
import '../models/merchant_item.dart';
import '../models/supplier_product.dart';
import '../providers/merchant_provider.dart';
import '../widgets/identity_header.dart';
import '../widgets/state_views.dart';
import '../widgets/supplier_product_card.dart';
import 'add_inventory_screen.dart';
import 'catalog_detail_screen.dart';

/// Screen #2 (List / Catalog): Menampilkan katalog produk grosir dari REST API.
class CatalogListScreen extends StatefulWidget {
  const CatalogListScreen({super.key});

  @override
  State<CatalogListScreen> createState() => _CatalogListScreenState();
}

class _CatalogListScreenState extends State<CatalogListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openDetail(
    BuildContext context,
    SupplierProduct product,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CatalogDetailScreen(product: product),
      ),
    );
  }

  Future<void> _openQuickKulakan(
    BuildContext context,
    SupplierProduct product,
  ) async {
    context.read<MerchantProvider>().selectDraftSupplierProduct(product);
    final MerchantItem? created = await Navigator.of(context).push<MerchantItem>(
      MaterialPageRoute<MerchantItem>(
        builder: (_) => AddInventoryScreen(
          initialProduct: product,
          isPushedRoute: true,
        ),
      ),
    );
    if (created != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berhasil menambahkan "${created.productTitle}" ke Stok Lapak!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final MerchantProvider provider = context.watch<MerchantProvider>();
    final List<SupplierProduct> products = provider.filteredCatalogProducts;
    final List<String> categories = provider.availableCatalogCategories;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final LayoutCategory category = layoutCategoryOf(constraints.maxWidth);
        final int columns = gridColumnsFor(category);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAF9),
          appBar: AppBar(
            title: const Text('Katalog Grosir'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Muat Ulang',
                onPressed: () => provider.loadCatalog(),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                color: const Color(0xFF6B7280),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opsi Pengujian',
                onSelected: (String value) {
                  if (value == 'simulate_error') {
                    provider.loadCatalog(simulateError: true);
                  } else if (value == 'reload') {
                    provider.loadCatalog();
                  }
                },
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'reload',
                    child: Text('GET Data Baru'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'simulate_error',
                    child: Text('Simulasi Error Jaringan'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: LayoutBadge(category: category),
              ),
            ],
          ),
          body: _buildBody(
            context: context,
            provider: provider,
            products: products,
            categories: categories,
            columns: columns,
          ),
        );
      },
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required MerchantProvider provider,
    required List<SupplierProduct> products,
    required List<String> categories,
    required int columns,
  }) {
    if (provider.isLoadingCatalog) {
      return const LoadingStateView(
        message: 'Mengambil katalog produk grosir dari REST API...',
      );
    }

    if (provider.catalogError != null) {
      return ErrorStateView(
        title: 'Gagal Memuat Katalog',
        message: provider.catalogError!,
        onRetry: () => provider.loadCatalog(),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0B6E4F),
      onRefresh: () => provider.loadCatalog(),
      child: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const IdentityHeader(
                    subtitle:
                        'Sumber Data: GET dummyjson.com/products • Pilih barang untuk kulakan',
                    dense: true,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    onChanged: provider.setCatalogSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Cari barang grosir atau brand...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Color(0xFF9CA3AF),
                      ),
                      suffixIcon: provider.catalogSearchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                provider.setCatalogSearchQuery('');
                              },
                              icon: const Icon(Icons.clear_rounded, size: 18),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF0B6E4F),
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: <Widget>[
                              FilterChip(
                                avatar: Icon(
                                  provider.onlyBookmarkedCatalog
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  'Pantauan (${provider.bookmarkCount})',
                                ),
                                selected: provider.onlyBookmarkedCatalog,
                                onSelected: provider.setOnlyBookmarkedCatalog,
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: 8),
                              ...categories.map((String cat) {
                                final bool selected =
                                    provider.selectedCatalogCategory == cat;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(cat),
                                    selected: selected,
                                    onSelected: (_) =>
                                        provider.setSelectedCatalogCategory(cat),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<CatalogSortOption>(
                        tooltip: 'Urutkan',
                        initialValue: provider.sortOption,
                        onSelected: provider.setSortOption,
                        icon: const Icon(
                          Icons.sort_rounded,
                          size: 20,
                          color: Color(0xFF6B7280),
                        ),
                        itemBuilder: (BuildContext context) {
                          return CatalogSortOption.values
                              .map(
                                (CatalogSortOption opt) =>
                                    PopupMenuItem<CatalogSortOption>(
                                  value: opt,
                                  child: Text(
                                    opt.label,
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${products.length} produk grosir • ${provider.sortOption.label}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateView(
                title: 'Produk Tidak Ditemukan',
                subtitle:
                    'Tidak ada produk supplier yang cocok dengan filter yang dipilih.',
                icon: Icons.search_off_rounded,
                actionLabel: 'Reset Filter',
                onAction: () {
                  _searchController.clear();
                  provider.resetCatalogFilters();
                },
              ),
            )
          else if (columns == 1)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList.separated(
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  final SupplierProduct product = products[index];
                  return SupplierProductCard(
                    product: product,
                    isBookmarked: provider.isProductBookmarked(product.id),
                    isInInventory: provider.isInMerchantInventory(product.id),
                    onTapDetail: () => _openDetail(context, product),
                    onToggleBookmark: () {
                      provider.toggleBookmark(product.id);
                    },
                    onQuickAddInventory: () =>
                        _openQuickKulakan(context, product),
                  );
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 220,
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final SupplierProduct product = products[index];
                    return SupplierProductCard(
                      product: product,
                      isBookmarked: provider.isProductBookmarked(product.id),
                      isInInventory: provider.isInMerchantInventory(product.id),
                      onTapDetail: () => _openDetail(context, product),
                      onToggleBookmark: () {
                        provider.toggleBookmark(product.id);
                      },
                      onQuickAddInventory: () =>
                          _openQuickKulakan(context, product),
                    );
                  },
                  childCount: products.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
