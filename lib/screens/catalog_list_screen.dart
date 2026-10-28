import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../core/breakpoint.dart';
import '../models/merchant_item.dart';
import '../models/supplier_product.dart';
import '../providers/merchant_provider.dart';
import '../widgets/identity_header.dart';
import '../widgets/state_views.dart';
import '../widgets/supplier_product_card.dart';
import 'add_inventory_screen.dart';
import 'catalog_detail_screen.dart';

/// Screen #2 (List / Catalog): Menampilkan katalog produk grosir dari REST API
/// (`GET https://dummyjson.com/products?limit=30`) dengan pencarian, filter
/// kategori, filter bookmark pantauan harga, pengurutan, dan layout responsif.
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
          appBar: AppBar(
            title: const Text('Katalog Grosir Supplier (REST API)'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Muat Ulang REST API',
                onPressed: () => provider.loadCatalog(),
                icon: const Icon(Icons.refresh),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opsi Pengujian REST API',
                onSelected: (String value) {
                  if (value == 'simulate_error') {
                    provider.loadCatalog(simulateError: true);
                  } else if (value == 'reload') {
                    provider.loadCatalog();
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'reload',
                    child: ListTile(
                      leading: Icon(Icons.cloud_download_outlined),
                      title: Text('GET Data Baru dari API'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'simulate_error',
                    child: ListTile(
                      leading: Icon(Icons.wifi_off_outlined),
                      title: Text('Simulasi Error Jaringan API'),
                      contentPadding: EdgeInsets.zero,
                    ),
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
        message:
            'Mengambil katalog produk grosir dari REST API (${ApiConfig.productsEndpoint})...',
      );
    }

    if (provider.catalogError != null) {
      return ErrorStateView(
        title: 'Gagal Memuat Katalog REST API',
        message: provider.catalogError!,
        onRetry: () => provider.loadCatalog(),
      );
    }

    return RefreshIndicator(
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
                        'Sumber Data: GET https://dummyjson.com/products • Pilih barang untuk kulakan',
                    dense: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: provider.setCatalogSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Cari barang grosir atau brand...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: provider.catalogSearchQuery.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      provider.setCatalogSearchQuery('');
                                    },
                                    icon: const Icon(Icons.clear),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<CatalogSortOption>(
                        tooltip: 'Urutkan Katalog',
                        initialValue: provider.sortOption,
                        onSelected: provider.setSortOption,
                        icon: const Icon(Icons.sort),
                        itemBuilder: (BuildContext context) {
                          return CatalogSortOption.values
                              .map(
                                (CatalogSortOption opt) =>
                                    PopupMenuItem<CatalogSortOption>(
                                  value: opt,
                                  child: Text(opt.label),
                                ),
                              )
                              .toList();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        FilterChip(
                          avatar: Icon(
                            provider.onlyBookmarkedCatalog
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: 16,
                          ),
                          label: Text(
                            'Pantauan (${provider.bookmarkCount})',
                          ),
                          selected: provider.onlyBookmarkedCatalog,
                          onSelected: provider.setOnlyBookmarkedCatalog,
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
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Menampilkan ${products.length} produk grosir',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        'Urutan: ${provider.sortOption.label}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateView(
                title: 'Produk Grosir Tidak Ditemukan',
                subtitle:
                    'Tidak ada produk supplier yang cocok dengan kata kunci atau filter yang dipilih.',
                icon: Icons.search_off_rounded,
                actionLabel: 'Reset Filter Katalog',
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
                  mainAxisExtent: 232,
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
