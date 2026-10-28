/// Identitas mahasiswa untuk Project UTS Pemrograman Mobile.
class Student {
  const Student({
    required this.name,
    required this.id,
    required this.major,
    required this.className,
    required this.initials,
    required this.appName,
    required this.appTheme,
  });

  final String name;
  final String id;
  final String major;
  final String className;
  final String initials;
  final String appName;
  final String appTheme;
}

/// Data identitas mahasiswa pemilik Project UTS.
const Student student = Student(
  name: 'Gede Pasek Ary Sugiantara',
  id: '2415051074',
  major: 'Pendidikan Teknik Informatika',
  className: 'PTI 5C',
  initials: 'PA',
  appName: 'LapakPintar',
  appTheme: 'Katalog Grosir Supplier & Manajemen Stok Pedagang UMKM',
);

/// URL repository GitHub sesuai format UTS_NIM_Nama.
const String repositoryUrl =
    'https://github.com/Destroy27/UTS_2415051074_Gede_Pasek_Ary_Sugiantara';

String get studentName => student.name;
String get studentId => student.id;
String get studentClass => student.className;
String get studentProgram => student.major;
String get studentInitials => student.initials;
String get identityLine => '${student.id} - ${student.name}';
