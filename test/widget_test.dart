import 'package:flutter_test/flutter_test.dart';
import 'package:lapak_pintar/core/breakpoint.dart';
import 'package:lapak_pintar/core/currency_formatter.dart';
import 'package:lapak_pintar/main.dart';
import 'package:lapak_pintar/models/merchant_item.dart';
import 'package:lapak_pintar/models/merchant_summary.dart';
import 'package:lapak_pintar/models/supplier_product.dart';
import 'package:lapak_pintar/repositories/merchant_repository.dart';
import 'package:lapak_pintar/services/merchant_database_service.dart';
import 'package:lapak_pintar/services/product_api_service.dart';

class _FakeProductApiService extends ProductApiService {
  @override
  Future<List<SupplierProduct>> fetchSupplierProducts({
    bool forceNetworkError = false,
  }) async {
    return ProductApiService.fallbackSupplierCatalog;
  }
}

void main() {
  test('Model SupplierProduct & MerchantSummary menghitung laba dengan benar', () {
    final SupplierProduct sample = SupplierProduct.fromJson(<String, dynamic>{
      'id': 10,
      'title': 'Beras Super 5Kg',
      'description': 'Beras kualitas premium untuk warung sembako',
      'category': 'groceries',
      'price': 4.0,
      'discountPercentage': 10.0,
      'rating': 4.8,
      'stock': 50,
      'brand': 'PadiMas',
      'sku': 'BRS-010',
      'thumbnail': '',
      'images': <String>[],
      'minimumOrderQuantity': 5,
    });

    expect(sample.categoryLabel, 'Sembako & Harian');
    expect(sample.wholesalePriceIdr, greaterThan(0));
    expect(sample.suggestedRetailPriceIdr, greaterThan(sample.wholesalePriceIdr));

    const MerchantItem item = MerchantItem(
      id: 1,
      studentId: '2415051074',
      productId: 10,
      productTitle: 'Beras Super 5Kg',
      category: 'Sembako & Harian',
      buyPrice: 60000,
      sellPrice: 68000,
      stockQty: 10,
      restockStatus: 'Stok Aman',
      merchantNote: 'Agen Makmur',
      rating: 5,
    );

    expect(item.profitPerUnit, 8000);
    expect(item.totalCapital, 600000);
    expect(item.totalProfitPotential, 80000);

    final MerchantSummary summary = MerchantSummary.fromItems(<MerchantItem>[item]);
    expect(summary.totalSkuCount, 1);
    expect(summary.totalUnitsInStock, 10);
    expect(summary.totalProfitPotentialIdr, 80000);
  });

  test('Breakpoint & CurrencyFormatter bekerja sesuai spesifikasi', () {
    expect(layoutCategoryOf(420), LayoutCategory.compact);
    expect(layoutCategoryOf(720), LayoutCategory.medium);
    expect(layoutCategoryOf(1024), LayoutCategory.expanded);
    expect(CurrencyFormatter.formatRupiah(15500), 'Rp 15.500');
  });

  testWidgets('LapakPintarApp menampilkan identitas mahasiswa dan navigasi utama', (
    WidgetTester tester,
  ) async {
    final MerchantRepository repository = MerchantRepository(
      apiService: _FakeProductApiService(),
      databaseService: MerchantDatabaseService(supabaseInitialized: false),
    );

    await tester.pumpWidget(LapakPintarApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Gede Pasek Ary Sugiantara'), findsWidgets);
    expect(find.textContaining('2415051074'), findsWidgets);
    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Katalog'), findsWidgets);
    expect(find.text('Stok'), findsWidgets);
  });
}
