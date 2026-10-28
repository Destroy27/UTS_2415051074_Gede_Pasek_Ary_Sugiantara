import 'package:flutter/foundation.dart';

import '../models/merchant_item.dart';
import '../models/merchant_summary.dart';
import '../models/supplier_product.dart';
import '../repositories/merchant_repository.dart';

/// Opsi pengurutan katalog produk grosir.
enum CatalogSortOption {
  popular('Rating Tertinggi'),
  lowestPrice('Harga Modal Termurah'),
  highestDiscount('Diskon Grosir Terbesar'),
  highestStock('Stok Supplier Terbanyak');

  const CatalogSortOption(this.label);
  final String label;
}

/// State Management utama aplikasi LapakPintar menggunakan `ChangeNotifier` (Provider).
///
/// Mengelola:
/// 1. Async State REST API Katalog Supplier (`isLoadingCatalog`, `catalogError`, `catalogProducts`)
/// 2. Async State Database Inventaris (`isLoadingInventory`, `inventoryError`, `inventoryItems`)
/// 3. Shared Application State:
///    - `bookmarkedProductIds`: Daftar produk supplier yang ditandai favorit/pantauan harga
///    - Filter pencarian, kategori, pengurutan katalog, dan filter status stok lapak
///    - Produk supplier yang dipilih untuk ditambahkan cepat ke form stok lapak.
class MerchantProvider extends ChangeNotifier {
  MerchantProvider({required MerchantRepository repository})
      : _repository = repository;

  final MerchantRepository _repository;

  // ==================== STATE KATALOG REST API ====================
  List<SupplierProduct> _catalogProducts = <SupplierProduct>[];
  bool _isLoadingCatalog = false;
  String? _catalogError;

  List<SupplierProduct> get catalogProducts => _catalogProducts;
  bool get isLoadingCatalog => _isLoadingCatalog;
  String? get catalogError => _catalogError;

  // ==================== STATE DATABASE INVENTARIS ====================
  List<MerchantItem> _inventoryItems = <MerchantItem>[];
  bool _isLoadingInventory = false;
  bool _isSubmitting = false;
  String? _inventoryError;

  List<MerchantItem> get inventoryItems => _inventoryItems;
  bool get isLoadingInventory => _isLoadingInventory;
  bool get isSubmitting => _isSubmitting;
  String? get inventoryError => _inventoryError;
  bool get isCloudDatabaseActive => _repository.isCloudDatabaseActive;

  // ==================== SHARED STATE (FAVORITES & FILTERS) ====================
  final Set<int> _bookmarkedProductIds = <int>{16, 20};
  String _catalogSearchQuery = '';
  String _selectedCatalogCategory = 'Semua';
  CatalogSortOption _sortOption = CatalogSortOption.popular;
  bool _onlyBookmarkedCatalog = false;

  String _inventorySearchQuery = '';
  String _selectedStockStatus = 'Semua';

  /// Produk dari Katalog API yang sedang dipilih untuk diisi otomatis pada Form Tambah.
  SupplierProduct? _draftSupplierProduct;

  Set<int> get bookmarkedProductIds =>
      Set<int>.unmodifiable(_bookmarkedProductIds);
  int get bookmarkCount => _bookmarkedProductIds.length;
  String get catalogSearchQuery => _catalogSearchQuery;
  String get selectedCatalogCategory => _selectedCatalogCategory;
  CatalogSortOption get sortOption => _sortOption;
  bool get onlyBookmarkedCatalog => _onlyBookmarkedCatalog;
  String get inventorySearchQuery => _inventorySearchQuery;
  String get selectedStockStatus => _selectedStockStatus;
  SupplierProduct? get draftSupplierProduct => _draftSupplierProduct;

  bool isProductBookmarked(int productId) =>
      _bookmarkedProductIds.contains(productId);

  /// Mengecek apakah suatu produk katalog sudah ada di dalam inventaris lapak.
  bool isInMerchantInventory(int productId) =>
      productId > 0 &&
      _inventoryItems.any((MerchantItem item) => item.productId == productId);

  /// Ringkasan statistik modal, stok, dan potensi keuntungan pedagang.
  MerchantSummary get summary => MerchantSummary.fromItems(_inventoryItems);

  /// Daftar kategori unik dari katalog REST API.
  List<String> get availableCatalogCategories {
    final Set<String> categories = <String>{'Semua'};
    for (final SupplierProduct p in _catalogProducts) {
      categories.add(p.categoryLabel);
    }
    return categories.toList();
  }

  /// Daftar produk katalog yang telah difilter & diurutkan sesuai interaksi pengguna.
  List<SupplierProduct> get filteredCatalogProducts {
    final String query = _catalogSearchQuery.trim().toLowerCase();

    final List<SupplierProduct> filtered = _catalogProducts.where((
      SupplierProduct product,
    ) {
      final bool matchesCategory = _selectedCatalogCategory == 'Semua' ||
          product.categoryLabel == _selectedCatalogCategory;
      final bool matchesBookmark = !_onlyBookmarkedCatalog ||
          _bookmarkedProductIds.contains(product.id);
      final bool matchesQuery = query.isEmpty ||
          product.title.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query) ||
          product.categoryLabel.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);

      return matchesCategory && matchesBookmark && matchesQuery;
    }).toList();

    switch (_sortOption) {
      case CatalogSortOption.popular:
        filtered.sort(
          (SupplierProduct a, SupplierProduct b) => b.rating.compareTo(a.rating),
        );
      case CatalogSortOption.lowestPrice:
        filtered.sort(
          (SupplierProduct a, SupplierProduct b) =>
              a.wholesalePriceIdr.compareTo(b.wholesalePriceIdr),
        );
      case CatalogSortOption.highestDiscount:
        filtered.sort(
          (SupplierProduct a, SupplierProduct b) =>
              b.discountPercentage.compareTo(a.discountPercentage),
        );
      case CatalogSortOption.highestStock:
        filtered.sort(
          (SupplierProduct a, SupplierProduct b) => b.stock.compareTo(a.stock),
        );
    }

    return filtered;
  }

  /// Daftar barang stok pedagang yang telah difilter berdasarkan pencarian & status stok.
  List<MerchantItem> get filteredInventoryItems {
    final String query = _inventorySearchQuery.trim().toLowerCase();

    return _inventoryItems.where((MerchantItem item) {
      final bool matchesStatus = _selectedStockStatus == 'Semua' ||
          item.restockStatus == _selectedStockStatus;
      final bool matchesQuery = query.isEmpty ||
          item.productTitle.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.merchantNote.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  // ==================== INTERAKSI SHARED STATE ====================

  void toggleBookmark(int productId) {
    if (!_bookmarkedProductIds.remove(productId)) {
      _bookmarkedProductIds.add(productId);
    }
    notifyListeners();
  }

  void setCatalogSearchQuery(String query) {
    if (_catalogSearchQuery == query) return;
    _catalogSearchQuery = query;
    notifyListeners();
  }

  void setSelectedCatalogCategory(String category) {
    if (_selectedCatalogCategory == category) return;
    _selectedCatalogCategory = category;
    notifyListeners();
  }

  void setSortOption(CatalogSortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    notifyListeners();
  }

  void setOnlyBookmarkedCatalog(bool value) {
    if (_onlyBookmarkedCatalog == value) return;
    _onlyBookmarkedCatalog = value;
    notifyListeners();
  }

  void resetCatalogFilters() {
    _catalogSearchQuery = '';
    _selectedCatalogCategory = 'Semua';
    _sortOption = CatalogSortOption.popular;
    _onlyBookmarkedCatalog = false;
    notifyListeners();
  }

  void setInventorySearchQuery(String query) {
    if (_inventorySearchQuery == query) return;
    _inventorySearchQuery = query;
    notifyListeners();
  }

  void setSelectedStockStatus(String status) {
    if (_selectedStockStatus == status) return;
    _selectedStockStatus = status;
    notifyListeners();
  }

  void selectDraftSupplierProduct(SupplierProduct? product) {
    _draftSupplierProduct = product;
    notifyListeners();
  }

  // ==================== OPERASI ASYNC REST API & DATABASE ====================

  Future<void> initializeData() async {
    await Future.wait(<Future<void>>[
      loadCatalog(),
      loadInventory(),
    ]);
  }

  /// Memuat katalog produk grosir dari REST API.
  Future<void> loadCatalog({bool simulateError = false}) async {
    _isLoadingCatalog = true;
    _catalogError = null;
    notifyListeners();

    try {
      _catalogProducts = await _repository.getCatalogProducts(
        forceNetworkError: simulateError,
      );
    } catch (e) {
      _catalogError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingCatalog = false;
      notifyListeners();
    }
  }

  /// Memuat daftar inventaris stok lapak dari Database.
  Future<void> loadInventory({bool simulateError = false}) async {
    _isLoadingInventory = true;
    _inventoryError = null;
    notifyListeners();

    try {
      _inventoryItems = await _repository.getInventoryItems(
        forceDatabaseError: simulateError,
      );
    } catch (e) {
      _inventoryError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingInventory = false;
      notifyListeners();
    }
  }

  /// CREATE: Menambah barang dagangan baru ke database.
  Future<MerchantItem> createItem(MerchantItem newItem) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      final MerchantItem created =
          await _repository.createInventoryItem(newItem);
      _inventoryItems = <MerchantItem>[created, ..._inventoryItems];
      _draftSupplierProduct = null;
      return created;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// UPDATE: Memperbarui data barang dagangan di database.
  Future<MerchantItem> updateItem(int id, MerchantItem updatedItem) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      final MerchantItem saved =
          await _repository.updateInventoryItem(id, updatedItem);
      final int idx =
          _inventoryItems.indexWhere((MerchantItem item) => item.id == id);
      if (idx != -1) {
        final List<MerchantItem> copy =
            List<MerchantItem>.from(_inventoryItems);
        copy[idx] = saved;
        _inventoryItems = copy;
      }
      return saved;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Quick Action: Menambah/mengurangi jumlah stok barang secara cepat (+1 / -1)
  /// dan otomatis menyesuaikan status stoknya.
  Future<void> adjustStockQuantity(MerchantItem item, int delta) async {
    if (item.id == null) return;
    final int newQty = (item.stockQty + delta).clamp(0, 99999);
    String newStatus = item.restockStatus;
    if (newQty == 0) {
      newStatus = 'Habis';
    } else if (newQty <= 5 && item.restockStatus == 'Stok Aman') {
      newStatus = 'Perlu Kulakan';
    } else if (newQty > 5 &&
        (item.restockStatus == 'Habis' ||
            item.restockStatus == 'Perlu Kulakan')) {
      newStatus = 'Stok Aman';
    }

    await updateItem(
      item.id!,
      item.copyWith(stockQty: newQty, restockStatus: newStatus),
    );
  }

  /// DELETE: Menghapus barang dagangan dari database.
  Future<void> deleteItem(int id) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _repository.deleteInventoryItem(id);
      _inventoryItems =
          _inventoryItems.where((MerchantItem item) => item.id != id).toList();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
