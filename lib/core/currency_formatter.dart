/// Utility pemformatan mata uang Rupiah (IDR) dan angka tanpa library eksternal.
class CurrencyFormatter {
  const CurrencyFormatter._();

  /// Memformat angka integer/num menjadi format Rupiah, contoh: `Rp 125.000`.
  static String formatRupiah(num value, {bool withPrefix = true}) {
    final int rounded = value.round();
    final bool isNegative = rounded < 0;
    final String digits = rounded.abs().toString();
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      final int positionFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }

    final String prefix = withPrefix ? 'Rp ' : '';
    final String sign = isNegative ? '-' : '';
    return '$sign$prefix${buffer.toString()}';
  }

  /// Memformat angka ringkas untuk dashboard, contoh: `Rp 1,4 Jt` atau `Rp 450 Rb`.
  static String formatCompactRupiah(num value) {
    final double absVal = value.abs().toDouble();
    final String sign = value < 0 ? '-' : '';
    if (absVal >= 1000000000) {
      return '${sign}Rp ${(absVal / 1000000000).toStringAsFixed(1)} M';
    }
    if (absVal >= 1000000) {
      return '${sign}Rp ${(absVal / 1000000).toStringAsFixed(1)} Jt';
    }
    if (absVal >= 100000) {
      return '${sign}Rp ${(absVal / 1000).toStringAsFixed(0)} Rb';
    }
    return formatRupiah(value);
  }
}
