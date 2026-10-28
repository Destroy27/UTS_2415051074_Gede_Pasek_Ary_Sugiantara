import '../models/merchant_item.dart';
import '../models/supplier_product.dart';
import '../services/merchant_database_service.dart';
import '../services/product_api_service.dart';

/// Repository Layer yang mengoordinasikan sumber data REST API (Katalog Grosir)
/// dan Backend Database Supabase (Inventaris Lapak Pedagang).
///
/// Sesuai prinsip arsitektur pada panduan UTS:
/// UI → State/Provider → Repository → Service/Data Source → REST API / Database.
class MerchantRepository {
  MerchantRepository({
    required ProductApiService apiService,
    required MerchantDatabaseService databaseService,
  })  : _apiService = apiService,
        _databaseService = databaseService;

  final ProductApiService _apiService;
  final MerchantDatabaseService _databaseService;

  bool get isCloudDatabaseActive => _databaseService.isCloudActive;

  Future<List<SupplierProduct>> getCatalogProducts({
    bool forceNetworkError = false,
  }) {
    return _apiService.fetchSupplierProducts(
      forceNetworkError: forceNetworkError,
    );
  }

  Future<List<MerchantItem>> getInventoryItems({
    bool forceDatabaseError = false,
  }) {
    return _databaseService.getInventoryItems(
      forceDatabaseError: forceDatabaseError,
    );
  }

  Future<MerchantItem> createInventoryItem(MerchantItem item) {
    return _databaseService.createInventoryItem(item);
  }

  Future<MerchantItem> updateInventoryItem(int id, MerchantItem item) {
    return _databaseService.updateInventoryItem(id, item);
  }

  Future<void> deleteInventoryItem(int id) {
    return _databaseService.deleteInventoryItem(id);
  }
}
