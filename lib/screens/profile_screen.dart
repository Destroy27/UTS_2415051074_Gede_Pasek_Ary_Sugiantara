import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../config/supabase_config.dart';
import '../core/breakpoint.dart';
import '../core/currency_formatter.dart';
import '../core/student_identity.dart';
import '../providers/merchant_provider.dart';
import '../widgets/identity_header.dart';

/// Screen #7 (Profile / About + Fitur Kreatif Kalkulator Laba Pedagang):
/// Menampilkan identitas mahasiswa, arsitektur aplikasi, status koneksi API
/// & Supabase, serta kalkulator interaktif simulasi harga grosir & target laba.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _modalPerPack = 120000;
  double _unitsPerPack = 12;
  double _desiredMarginPercent = 25;

  @override
  Widget build(BuildContext context) {
    final MerchantProvider provider = context.watch<MerchantProvider>();
    final int unitModal = (_modalPerPack / _unitsPerPack).round();
    final int rawSellUnit =
        (unitModal * (1 + _desiredMarginPercent / 100)).round();
    final int roundedSellUnit = ((rawSellUnit / 500).ceil() * 500);
    final int profitPerUnit = roundedSellUnit - unitModal;
    final int profitPerPack = profitPerUnit * _unitsPerPack.round();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final LayoutCategory category = layoutCategoryOf(constraints.maxWidth);
        final bool isWide = category != LayoutCategory.compact;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil Mahasiswa & Kalkulator Dagang'),
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
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const IdentityHeader(),
                    const SizedBox(height: 16),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(child: _buildStudentCard(context)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTechArchitectureCard(
                              context,
                              provider,
                            ),
                          ),
                        ],
                      )
                    else ...<Widget>[
                      _buildStudentCard(context),
                      const SizedBox(height: 16),
                      _buildTechArchitectureCard(context, provider),
                    ],
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Icon(
                                  Icons.calculate_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Fitur Kreatif: Kalkulator Pecah Harga Dus / Renteng Pedagang',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Bantu pedagang menghitung harga jual eceran per biji saat membeli barang secara grosir per dus/pak:',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Harga Beli 1 Dus / Pak: ${CurrencyFormatter.formatRupiah(_modalPerPack)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Slider(
                              value: _modalPerPack,
                              min: 15000,
                              max: 500000,
                              divisions: 97,
                              label:
                                  CurrencyFormatter.formatRupiah(_modalPerPack),
                              onChanged: (double v) =>
                                  setState(() => _modalPerPack = v),
                            ),
                            Text(
                              'Isi Barang per Dus / Renteng: ${_unitsPerPack.round()} pcs',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Slider(
                              value: _unitsPerPack,
                              min: 2,
                              max: 48,
                              divisions: 46,
                              label: '${_unitsPerPack.round()} pcs',
                              onChanged: (double v) =>
                                  setState(() => _unitsPerPack = v),
                            ),
                            Text(
                              'Target Margin Keuntungan: ${_desiredMarginPercent.round()}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Slider(
                              value: _desiredMarginPercent,
                              min: 5,
                              max: 60,
                              divisions: 55,
                              label: '${_desiredMarginPercent.round()}%',
                              onChanged: (double v) =>
                                  setState(() => _desiredMarginPercent = v),
                            ),
                            const Divider(height: 20),
                            Wrap(
                              spacing: 20,
                              runSpacing: 12,
                              alignment: WrapAlignment.spaceBetween,
                              children: <Widget>[
                                _ResultBox(
                                  label: 'Modal per Pcs',
                                  value: CurrencyFormatter.formatRupiah(
                                    unitModal,
                                  ),
                                ),
                                _ResultBox(
                                  label: 'Saran Jual Eceran / Pcs',
                                  value: CurrencyFormatter.formatRupiah(
                                    roundedSellUnit,
                                  ),
                                  highlight: true,
                                ),
                                _ResultBox(
                                  label: 'Untung per Pcs',
                                  value:
                                      '+${CurrencyFormatter.formatRupiah(profitPerUnit)}',
                                ),
                                _ResultBox(
                                  label: 'Total Untung 1 Dus',
                                  value:
                                      '+${CurrencyFormatter.formatRupiah(profitPerPack)}',
                                  highlight: true,
                                ),
                              ],
                            ),
                          ],
                        ),
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

  Widget _buildStudentCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Identitas Mahasiswa (UTS)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 20),
            _InfoRow(label: 'Nama Lengkap', value: studentName),
            _InfoRow(label: 'NIM', value: studentId),
            _InfoRow(label: 'Kelas', value: studentClass),
            _InfoRow(label: 'Program Studi', value: studentProgram),
            _InfoRow(label: 'Nama Project', value: student.appName),
            _InfoRow(label: 'Tema Aplikasi', value: student.appTheme),
            _InfoRow(
              label: 'Dosen Pengampu',
              value: 'Dr. Ir. I Ketut Resika Arthana, S.T., M.Kom',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechArchitectureCard(
    BuildContext context,
    MerchantProvider provider,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Spesifikasi Teknis & Integrasi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 20),
            const _InfoRow(
              label: 'Arsitektur',
              value: 'UI → Provider → Repository → Service → API/DB',
            ),
            const _InfoRow(
              label: 'State Management',
              value: 'Provider + ChangeNotifier (MerchantProvider)',
            ),
            const _InfoRow(
              label: 'REST API (GET)',
              value: ApiConfig.productsEndpoint,
            ),
            _InfoRow(
              label: 'Tabel Supabase',
              value: SupabaseConfig.inventoryTable,
            ),
            _InfoRow(
              label: 'Status Database',
              value: provider.isCloudDatabaseActive
                  ? 'Terhubung ke Supabase PostgreSQL Cloud'
                  : 'Mode Lokal Aktif (Isi URL & Key di supabase_config.dart)',
            ),
            const _InfoRow(
              label: 'Jumlah Screen',
              value: '7 Screen Fungsional (Home, Katalog, Detail, Stok, Tambah, Edit, Profil)',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  const _ResultBox({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: highlight ? Colors.green.shade800 : null,
              ),
        ),
      ],
    );
  }
}
