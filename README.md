# LapakPintar — Aplikasi Katalog Grosir Supplier & Manajemen Stok Pedagang UMKM

**LapakPintar** adalah aplikasi mobile Flutter untuk membantu pedagang warung/toko kelontong UMKM mengecek katalog harga modal barang grosir dari supplier melalui **REST API** serta mencatat dan mengelola inventaris stok, status kulakan, dan estimasi keuntungan warung pada **Backend Database Supabase PostgreSQL**.

Project ini disusun untuk memenuhi penugasan **Ujian Tengah Semester (UTS) Pemrograman Mobile**.

---

## 1. Identitas Mahasiswa

| Atribut | Keterangan |
| --- | --- |
| **Nama** | Gede Pasek Ary Sugiantara |
| **NIM** | 2415051074 |
| **Kelas** | PTI 5C |
| **Program Studi** | Pendidikan Teknik Informatika |
| **Mata Kuliah** | Pemrograman Mobile |
| **Dosen Pengampu** | Dr. Ir. I Ketut Resika Arthana, S.T., M.Kom |
| **Teaching Assistant** | Made Yuda Sadewa, S.Pd. |
| **Tema Project** | Pedagang / UMKM (*Katalog Grosir Supplier & Manajemen Stok Pedagang*) |

---

## 2. Daftar Fitur Aplikasi

1. **Dashboard Analitik Pedagang (`HomeScreen`)**
   - Menampilkan ringkasan total modal stok, potensi laba bersih, jumlah barang yang perlu kulakan segera, dan jumlah produk grosir yang dipantau.
   - Daftar belanja prioritas untuk barang berstatus `Perlu Kulakan` atau `Habis`.
   - Rekomendasi produk grosir terpopuler dari REST API.
2. **Katalog Grosir Supplier dari REST API (`CatalogListScreen`)**
   - Mengambil data katalog produk dari REST API publik menggunakan HTTP `GET`.
   - Pencarian real-time berdasarkan nama barang, brand, atau kategori.
   - Filter berdasarkan kategori (`Sembako & Harian`, `Kosmetik & Sabun`, `Parfum & Pewangi`, `Perlengkapan Rumah`) serta filter khusus produk yang di-*bookmark* (`Pantauan Harga`).
   - Pengurutan katalog berdasarkan Rating Tertinggi, Harga Modal Termurah, Diskon Terbesar, atau Stok Terbanyak.
3. **Detail Produk Supplier & Simulasi Kulakan (`CatalogDetailScreen`)**
   - Navigasi `List → Detail` dengan *passing data* objek `SupplierProduct`.
   - Kalkulator simulasi kuantitas kulakan menggunakan `Slider` interaktif.
   - Tombol **"Masuk ke Stok Lapak (Database)"** yang meneruskan data produk dari REST API ke halaman Form Tambah Stok secara otomatis.
4. **Manajemen Stok Lapak — Database CRUD (`InventoryListScreen`)**
   - Menampilkan daftar stok barang dagangan dari tabel `merchant_inventory` pada database Supabase.
   - Filter berdasarkan status stok (`Semua`, `Stok Aman`, `Perlu Kulakan`, `Habis`, `Rencana Beli`).
   - Tombol aksi cepat `+1` dan `-1` untuk mengubah jumlah stok secara instan.
   - Penghapusan data (`DELETE`) dilengkapi **Confirmation Dialog (`AlertDialog`)** dan feedback `SnackBar`.
5. **Form Tambah Stok & Kulakan (`AddInventoryScreen`)**
   - Operasi `CREATE` ke database dengan validasi `Form` lengkap (nama barang, kategori, harga modal, harga jual >= harga modal, jumlah stok, rating laris, dan catatan pedagang).
   - Tombol bantu hitung margin otomatis (`+15%`, `+25%`, `+35%` dari harga modal).
6. **Form Edit Stok & Catatan Barang (`EditInventoryScreen`)**
   - Operasi `UPDATE` data barang dagangan di database dengan pratinjau laba real-time.
7. **Profil Mahasiswa & Kalkulator Pecah Harga Dus/Renteng (`ProfileScreen`)**
   - Menampilkan identitas mahasiswa, spesifikasi arsitektur, serta fitur kreatif **Kalkulator Pecah Harga Dus/Renteng** untuk membantu pedagang menentukan harga jual eceran per pcs.
8. **Responsive Layout (3 Breakpoint Conditions)**
   - **Compact (`< 600px`)**: Navigasi bawah `NavigationBar` dan daftar 1 kolom.
   - **Medium (`600px – 840px`)**: Navigasi bawah `NavigationBar` dan `GridView` 2 kolom.
   - **Expanded (`≥ 840px`)**: Navigasi samping `NavigationRail` dan `GridView` 3 kolom.
9. **Penanganan Loading, Error, dan Empty State**
   - Seluruh operasi async REST API dan Database dilengkapi tampilan `LoadingStateView`, `ErrorStateView` (dengan tombol *Coba Lagi*), dan `EmptyStateView`.

---

## 3. Tech Stack

- **Framework**: Flutter 3.x (Material 3)
- **Bahasa Pemrograman**: Dart 3.x (Null Safety, Async/Await)
- **State Management**: `provider` (`ChangeNotifier`, `ChangeNotifierProvider`, `context.watch`, `context.read`)
- **HTTP Client**: `http` (`^1.6.0`)
- **Backend & Database**: `supabase_flutter` (`^2.8.3`) — Supabase PostgreSQL + Row Level Security (RLS)

---

## 4. REST API yang Digunakan

- **Nama API**: DummyJSON Products REST API
- **Method & Endpoint**: `GET https://dummyjson.com/products?limit=30`
- **Fungsi pada Aplikasi**: Mengambil katalog produk supplier grosir (nama produk, kategori, harga modal, diskon grosir, stok gudang supplier, brand, SKU, rating, deskripsi, dan gambar thumbnail) yang kemudian dikonversi menjadi model Dart `SupplierProduct`.

---

## 5. Backend & Database yang Digunakan

- **Platform**: Supabase (PostgreSQL)
- **Nama Tabel Utama**: `public.merchant_inventory`
- **Struktur Kolom Tabel** (Primary Key + 11 Field Data):
  - `id` (`bigint`, Primary Key, Identity)
  - `student_id` (`text` — NIM mahasiswa `2415051074`)
  - `product_id` (`integer` — ID referensi produk dari REST API)
  - `product_title` (`text` — Nama barang dagangan)
  - `category` (`text` — Kategori barang)
  - `buy_price` (`integer` — Harga beli/modal per unit dalam Rupiah)
  - `sell_price` (`integer` — Harga jual eceran per unit dalam Rupiah)
  - `stock_qty` (`integer` — Jumlah stok barang di warung)
  - `restock_status` (`text` — `'Stok Aman'`, `'Perlu Kulakan'`, `'Habis'`, `'Rencana Beli'`)
  - `merchant_note` (`text` — Catatan pedagang / nama agen grosir)
  - `rating` (`integer` — Tingkat perputaran/laris 1–5)
  - `thumbnail_url` (`text` — URL gambar barang)
  - `created_at` (`timestamptz` — Waktu pencatatan)
- **Keamanan**: Hanya menggunakan `publishable` / `anon` key di sisi client dan menerapkan Row Level Security (RLS). Tidak menyimpan `service_role` key pada aplikasi.

---

## 6. Struktur Arsitektur Aplikasi

Aplikasi menerapkan pemisahan tanggung jawab berlapis:
**`UI (Screens & Widgets) → State/Provider → Repository → Service → REST API / Supabase Database`**

```text
lib/
├── config/
│   ├── api_config.dart                 # Konfigurasi URL REST API & kurs IDR
│   └── supabase_config.dart            # Konfigurasi URL & Anon Key Supabase
├── core/
│   ├── breakpoint.dart                 # Responsive breakpoint (Compact, Medium, Expanded)
│   ├── currency_formatter.dart         # Pemformat mata uang Rupiah (Rp)
│   └── student_identity.dart           # Konstanta identitas mahasiswa
├── models/
│   ├── supplier_product.dart           # Model Dart #1: Katalog Produk REST API
│   ├── merchant_item.dart              # Model Dart #2: Barang Stok Database Supabase
│   └── merchant_summary.dart           # Model Dart #3: Ringkasan Analitik Pedagang
├── services/
│   ├── product_api_service.dart        # Service HTTP GET ke REST API
│   └── merchant_database_service.dart  # Service CRUD ke Supabase + Smart Local Fallback
├── repositories/
│   └── merchant_repository.dart        # Repository penghubung Provider dengan Services
├── providers/
│   └── merchant_provider.dart          # ChangeNotifier (Shared State, Filter, Async CRUD)
├── screens/
│   ├── home_screen.dart                # Screen #1: Dashboard & Ringkasan Lapak
│   ├── catalog_list_screen.dart        # Screen #2: Katalog Grosir Supplier (REST API)
│   ├── catalog_detail_screen.dart      # Screen #3: Detail Produk & Simulasi Kulakan
│   ├── add_inventory_screen.dart       # Screen #4: Form Tambah Stok (Create Database)
│   ├── edit_inventory_screen.dart      # Screen #5: Form Edit Stok (Update Database)
│   ├── inventory_list_screen.dart      # Screen #6: Daftar Stok Lapak & Delete Dialog
│   └── profile_screen.dart             # Screen #7: Profil Mahasiswa & Kalkulator Dus
├── widgets/
│   ├── app_shell.dart                  # Reusable Widget: NavigationBar & NavigationRail
│   ├── identity_header.dart            # Reusable Widget: Header Identitas & LayoutBadge
│   ├── merchant_item_card.dart         # Reusable Widget: Kartu Stok Barang Database
│   ├── state_views.dart                # Reusable Widget: Loading, Error, & Empty State
│   ├── summary_stat_card.dart          # Reusable Widget: Kartu Statistik Dashboard
│   └── supplier_product_card.dart      # Reusable Widget: Kartu Produk Katalog API
└── main.dart                           # Entry point aplikasi & Provider injection
```

---

## 7. Screenshot Aplikasi

> Tempelkan tangkapan layar aplikasi pada folder `screenshots/` saat pengumpulan akhir:
> - `screenshots/01_home_dashboard.png` — Home/Dashboard Screen
> - `screenshots/02_catalog_api_list.png` — Katalog Grosir REST API (List/Grid)
> - `screenshots/03_catalog_detail.png` — Detail Produk & Simulasi Kulakan
> - `screenshots/04_create_inventory.png` — Form Tambah Stok & Validasi
> - `screenshots/05_inventory_database.png` — Daftar Stok Lapak dari Database
> - `screenshots/06_edit_and_delete_dialog.png` — Form Edit & Dialog Konfirmasi Hapus
> - `screenshots/07_responsive_wide.png` — Tampilan Wide/Expanded dengan NavigationRail

---

## 8. Cara Menjalankan Project

### A. Persiapan Dependency
```bash
cd lapak_pintar
flutter pub get
```

### B. Konfigurasi Database Supabase Baru (Opsional namun Direkomendasikan)
1. Buat project baru di [Supabase Dashboard](https://supabase.com/dashboard).
2. Buka menu **SQL Editor**, salin seluruh isi file [`supabase_setup.sql`](./supabase_setup.sql), lalu klik **Run** untuk membuat tabel `merchant_inventory` beserta kebijakan RLS dan data awalnya.
3. Buka **Project Settings > API Keys**, lalu salin **Project URL** dan **Anon / Publishable Key** ke dalam file `lib/config/supabase_config.dart`:
   ```dart
   static const String url = 'https://PROJECT_ID_ANDA.supabase.co';
   static const String publishableKey = 'ANON_ATAU_PUBLISHABLE_KEY_ANDA';
   ```
   *(Catatan: Apabila belum diisi, aplikasi otomatis berjalan menggunakan mode penyimpanan lokal cerdas sehingga seluruh fitur CRUD tetap dapat diuji secara langsung tanpa error).*

### C. Menjalankan Aplikasi
```bash
# Menjalankan di Chrome / Desktop Windows (mudah menguji responsive layout Compact vs Expanded)
flutter run -d windows
# atau di perangkat Android / Emulator
flutter run
```

### D. Menjalankan Pengujian & Analisis Kode
```bash
flutter analyze
flutter test
```
