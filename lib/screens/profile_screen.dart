import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../config/supabase_config.dart';
import '../core/breakpoint.dart';
import '../core/currency_formatter.dart';
import '../core/student_identity.dart';
import '../providers/merchant_provider.dart';
import '../widgets/identity_header.dart';

/// Screen #7: Profil Mahasiswa & Kalkulator Pecah Harga Dus.
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
          backgroundColor: const Color(0xFFF8FAF9),
          appBar: AppBar(
            title: const Text('Profil & Kalkulator'),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: LayoutBadge(category: category),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
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
                            child: _buildTechCard(context, provider),
                          ),
                        ],
                      )
                    else ...<Widget>[
                      _buildStudentCard(context),
                      const SizedBox(height: 16),
                      _buildTechCard(context, provider),
                    ],
                    const SizedBox(height: 16),
                    _buildCalculatorCard(
                      context,
                      unitModal,
                      roundedSellUnit,
                      profitPerUnit,
                      profitPerPack,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Identitas Mahasiswa',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D1A),
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Nama', value: studentName),
          _InfoRow(label: 'NIM', value: studentId),
          _InfoRow(label: 'Kelas', value: studentClass),
          _InfoRow(label: 'Program Studi', value: studentProgram),
          _InfoRow(label: 'Project', value: student.appName),
          _InfoRow(label: 'Tema', value: student.appTheme),
          _InfoRow(label: 'Dosen', value: 'Dr. Ir. I Ketut Resika Arthana, S.T., M.Kom'),
        ],
      ),
    );
  }

  Widget _buildTechCard(BuildContext context, MerchantProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Spesifikasi Teknis',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D1A),
            ),
          ),
          const SizedBox(height: 12),
          const _InfoRow(
            label: 'Arsitektur',
            value: 'UI → Provider → Repository → Service → API/DB',
          ),
          const _InfoRow(
            label: 'State Mgmt',
            value: 'Provider + ChangeNotifier',
          ),
          _InfoRow(
            label: 'REST API',
            value: ApiConfig.productsEndpoint,
          ),
          _InfoRow(
            label: 'Tabel DB',
            value: SupabaseConfig.inventoryTable,
          ),
          _InfoRow(
            label: 'Status DB',
            value: provider.isCloudDatabaseActive
                ? 'Supabase Cloud'
                : 'Mode Lokal Aktif',
          ),
          const _InfoRow(
            label: 'Screen',
            value: '7 Screen Fungsional',
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorCard(
    BuildContext context,
    int unitModal,
    int roundedSellUnit,
    int profitPerUnit,
    int profitPerPack,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.calculate_rounded,
                size: 20,
                color: Color(0xFF0B6E4F),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kalkulator Pecah Harga Dus / Renteng',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1D1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Hitung harga jual eceran per pcs saat beli barang grosir per dus/pak.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Harga Beli 1 Dus: ${CurrencyFormatter.formatRupiah(_modalPerPack)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1D1A),
            ),
          ),
          Slider(
            value: _modalPerPack,
            min: 15000,
            max: 500000,
            divisions: 97,
            activeColor: const Color(0xFF0B6E4F),
            label: CurrencyFormatter.formatRupiah(_modalPerPack),
            onChanged: (double v) => setState(() => _modalPerPack = v),
          ),
          Text(
            'Isi per Dus: ${_unitsPerPack.round()} pcs',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1D1A),
            ),
          ),
          Slider(
            value: _unitsPerPack,
            min: 2,
            max: 48,
            divisions: 46,
            activeColor: const Color(0xFF0B6E4F),
            label: '${_unitsPerPack.round()} pcs',
            onChanged: (double v) => setState(() => _unitsPerPack = v),
          ),
          Text(
            'Target Margin: ${_desiredMarginPercent.round()}%',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1D1A),
            ),
          ),
          Slider(
            value: _desiredMarginPercent,
            min: 5,
            max: 60,
            divisions: 55,
            activeColor: const Color(0xFF0B6E4F),
            label: '${_desiredMarginPercent.round()}%',
            onChanged: (double v) =>
                setState(() => _desiredMarginPercent = v),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Wrap(
              spacing: 24,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              children: <Widget>[
                _ResultBox(
                  label: 'Modal / Pcs',
                  value: CurrencyFormatter.formatRupiah(unitModal),
                ),
                _ResultBox(
                  label: 'Saran Jual / Pcs',
                  value: CurrencyFormatter.formatRupiah(roundedSellUnit),
                  highlight: true,
                ),
                _ResultBox(
                  label: 'Untung / Pcs',
                  value: '+${CurrencyFormatter.formatRupiah(profitPerUnit)}',
                ),
                _ResultBox(
                  label: 'Total Untung 1 Dus',
                  value: '+${CurrencyFormatter.formatRupiah(profitPerPack)}',
                  highlight: true,
                ),
              ],
            ),
          ),
        ],
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
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1D1A),
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
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: highlight
                ? const Color(0xFF059669)
                : const Color(0xFF1A1D1A),
          ),
        ),
      ],
    );
  }
}
