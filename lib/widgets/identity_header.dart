import 'package:flutter/material.dart';

import '../core/breakpoint.dart';
import '../core/student_identity.dart';

/// Reusable Widget #1: Header Identitas Mahasiswa & Info Lapak Pedagang.
///
/// Ditampilkan secara konsisten agar bukti screenshot UTS selalu memuat
/// Nama, NIM, dan Kelas mahasiswa sesuai ketentuan penilaian.
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 12 : 16,
        vertical: dense ? 10 : 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            colors.primaryContainer,
            colors.secondaryContainer.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: dense ? 18 : 22,
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            child: Text(
              studentInitials,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: dense ? 12 : 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        studentClass,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle ?? 'NIM: $studentId • ${student.appName} UMKM',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onPrimaryContainer.withValues(alpha: 0.85),
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
      LayoutCategory.compact => Icons.smartphone,
      LayoutCategory.medium => Icons.tablet_android,
      LayoutCategory.expanded => Icons.desktop_windows_outlined,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: colors.onTertiaryContainer),
          const SizedBox(width: 4),
          Text(
            category.shortLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onTertiaryContainer,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
