/// Kategori layout hasil perhitungan breakpoint lebar layar (Responsive Layout).
enum LayoutCategory {
  compact,
  medium,
  expanded;

  String get label {
    switch (this) {
      case LayoutCategory.compact:
        return 'Compact (<600px)';
      case LayoutCategory.medium:
        return 'Medium (600-840px)';
      case LayoutCategory.expanded:
        return 'Expanded (≥840px)';
    }
  }

  String get shortLabel {
    switch (this) {
      case LayoutCategory.compact:
        return 'Compact';
      case LayoutCategory.medium:
        return 'Medium';
      case LayoutCategory.expanded:
        return 'Expanded';
    }
  }
}

/// Batas maksimum lebar layar Compact (Phone Portrait).
const double kCompactMaxWidth = 600;

/// Batas maksimum lebar layar Medium (Tablet / Phone Landscape).
const double kMediumMaxWidth = 840;

/// Menentukan [LayoutCategory] berdasarkan lebar ruang (constraints/MediaQuery).
LayoutCategory layoutCategoryOf(double width) {
  if (width < kCompactMaxWidth) {
    return LayoutCategory.compact;
  }
  if (width < kMediumMaxWidth) {
    return LayoutCategory.medium;
  }
  return LayoutCategory.expanded;
}

/// Menentukan jumlah kolom GridView katalog/inventaris secara responsif.
int gridColumnsFor(LayoutCategory category) {
  switch (category) {
    case LayoutCategory.compact:
      return 1;
    case LayoutCategory.medium:
      return 2;
    case LayoutCategory.expanded:
      return 3;
  }
}
