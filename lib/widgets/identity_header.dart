import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/breakpoint.dart';
import '../core/student_identity.dart';

/// Reusable Widget #1: Header Identitas Mahasiswa & Info Lapak Pedagang.
///
/// Tampilan modern & minimalis dengan tipografi Inter, aksen warna lembut,
/// dan spacing yang lapang agar ramah mata.
class IdentityHeader extends StatelessWidget {
  const IdentityHeader({
    super.key,
    this.subtitle,
    this.dense = false,
    this.trailing,
  });

  final String? subtitle;
  final bool dense;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 14 : 18,
        vertical: dense ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: dense ? 36 : 44,
            height: dense ? 36 : 44,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(dense ? 10 : 12),
            ),
            alignment: Alignment.center,
            child: Text(
              studentInitials,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: dense ? 13 : 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        studentName,
                        style: GoogleFonts.inter(
                          fontSize: dense ? 13 : 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1D1A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        studentClass,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle ?? 'NIM: $studentId • ${student.appName} UMKM',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Badge indikator kondisi layout responsif (Compact / Medium / Expanded).
class LayoutBadge extends StatelessWidget {
  const LayoutBadge({super.key, required this.category});

  final LayoutCategory category;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final IconData icon = switch (category) {
      LayoutCategory.compact => Icons.smartphone_outlined,
      LayoutCategory.medium => Icons.tablet_android_outlined,
      LayoutCategory.expanded => Icons.desktop_windows_outlined,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: const Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Text(
            category.shortLabel,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
