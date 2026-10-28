/// Konfigurasi endpoint REST API untuk Katalog Produk Supplier / Grosir.
class ApiConfig {
  const ApiConfig._();

  /// Base URL REST API publik DummyJSON Products.
  static const String baseUrl = 'https://dummyjson.com';

  /// Endpoint GET daftar produk grosir/supplier.
  static const String productsEndpoint = '$baseUrl/products?limit=30';

  /// Kurs konversi harga USD ke Rupiah agar kontekstual untuk pedagang UMKM.
  static const int usdToIdrRate = 15500;
}
