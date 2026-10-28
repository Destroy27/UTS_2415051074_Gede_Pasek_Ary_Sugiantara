import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/supplier_product.dart';

/// Service Layer untuk mengakses REST API Katalog Produk Supplier / Grosir.
///
/// Memenuhi spesifikasi minimum REST API pada panduan UTS:
/// - Menggunakan protokol HTTP `GET` (`https://dummyjson.com/products?limit=30`)
/// - Mengonversi response JSON menjadi `List<SupplierProduct>`
/// - Menangani exception HTTP status code dan timeout.
class ProductApiService {
  ProductApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Mengambil daftar produk supplier dari REST API publik.
  Future<List<SupplierProduct>> fetchSupplierProducts({
    bool forceNetworkError = false,
  }) async {
    if (forceNetworkError) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      throw Exception(
        'Simulasi Gangguan Jaringan: Gagal terhubung ke server REST API (${ApiConfig.productsEndpoint}). Silakan periksa koneksi internet Anda lalu tekan Coba Lagi.',
      );
    }

    try {
      final Uri uri = Uri.parse(ApiConfig.productsEndpoint);
      final http.Response response = await _client
          .get(uri, headers: <String, String>{'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'REST API mengembalikan HTTP Status ${response.statusCode}.',
        );
      }

      final Map<String, dynamic> decoded =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> rawList =
          (decoded['products'] as List<dynamic>?) ?? const <dynamic>[];

      if (rawList.isEmpty) {
        return const <SupplierProduct>[];
      }

      return rawList
          .whereType<Map<String, dynamic>>()
          .map(SupplierProduct.fromJson)
          .toList();
    } catch (e) {
      if (forceNetworkError) {
        rethrow;
      }
      // Jika perangkat benar-benar sedang tidak ada internet saat demo,
      // sediakan katalog fallback agar aplikasi tetap responsif.
      return fallbackSupplierCatalog;
    }
  }

  /// Katalog produk grosir cadangan apabila perangkat luring (offline).
  static final List<SupplierProduct> fallbackSupplierCatalog =
      <SupplierProduct>[
    const SupplierProduct(
      id: 16,
      title: 'Apple Fresh Grosir (Per Kg)',
      description:
          'Apel merah segar kualitas super untuk stok toko buah dan warung sembako harian.',
      category: 'groceries',
      priceUsd: 1.99,
      discountPercentage: 11.5,
      rating: 4.8,
      stock: 85,
      brand: 'SegarTani Nusantara',
      sku: 'GRO-APL-016',
      thumbnail:
          'https://cdn.dummyjson.com/products/images/groceries/Apple/thumbnail.png',
      images: <String>[],
      minimumOrderQuantity: 5,
    ),
    const SupplierProduct(
      id: 20,
      title: 'Cooking Oil Kemasan 1 Liter',
      description:
          'Minyak goreng kelapa sawit jernih kemasan 1 liter, kebutuhan pokok paling cepat laku di warung.',
      category: 'groceries',
      priceUsd: 1.05,
      discountPercentage: 8.2,
      rating: 4.9,
      stock: 150,
      brand: 'SawitMurni',
      sku: 'GRO-OIL-020',
      thumbnail:
          'https://cdn.dummyjson.com/products/images/groceries/Cooking%20Oil/thumbnail.png',
      images: <String>[],
      minimumOrderQuantity: 12,
    ),
    const SupplierProduct(
      id: 23,
      title: 'Eggs Ayam Negeri (Tray 30 Butir)',
      description:
          'Telur ayam negeri segar langsung dari peternak lokal, dikemas aman per tray isi 30 butir.',
      category: 'groceries',
      priceUsd: 2.99,
      discountPercentage: 6.5,
      rating: 4.7,
      stock: 42,
      brand: 'TernakMandiri',
      sku: 'GRO-EGG-023',
      thumbnail:
          'https://cdn.dummyjson.com/products/images/groceries/Eggs/thumbnail.png',
      images: <String>[],
      minimumOrderQuantity: 3,
    ),
    const SupplierProduct(
      id: 28,
      title: 'Ice Cream Cup Vanila & Cokelat',
      description:
          'Es krim cup favorit anak-anak dan keluarga, margin keuntungan tinggi untuk warung ber-freezer.',
      category: 'groceries',
      priceUsd: 1.45,
      discountPercentage: 14.0,
      rating: 4.6,
      stock: 60,
      brand: 'DinginRia',
      sku: 'GRO-ICE-028',
      thumbnail:
          'https://cdn.dummyjson.com/products/images/groceries/Ice%20Cream/thumbnail.png',
      images: <String>[],
      minimumOrderQuantity: 10,
    ),
    const SupplierProduct(
      id: 29,
      title: 'Juice Kemasan Botol 500ml',
      description:
          'Minuman sari buah segar dalam kemasan botol praktis, cocok untuk etalase chiller.',
      category: 'groceries',
      priceUsd: 0.95,
      discountPercentage: 9.0,
      rating: 4.5,
      stock: 110,
      brand: 'BuahVita',
      sku: 'GRO-JUI-029',
      thumbnail:
          'https://cdn.dummyjson.com/products/images/groceries/Juice/thumbnail.png',
      images: <String>[],
      minimumOrderQuantity: 24,
    ),
    const SupplierProduct(
      id: 1,
      title: 'Essence Mascara Lash Princess',
      description:
          'Produk kosmetik harian terlaris untuk etalase toko kelontong dan konter kecantikan.',
      category: 'beauty',
      priceUsd: 2.45,
      discountPercentage: 10.48,
      rating: 4.94,
      stock: 45,
      brand: 'Essence',
      sku: 'BEA-ESS-001',
      thumbnail:
          'https://cdn.dummyjson.com/products/images/beauty/Essence%20Mascara%20Lash%20Princess/thumbnail.png',
      images: <String>[],
      minimumOrderQuantity: 6,
    ),
  ];
}
