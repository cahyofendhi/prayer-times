/// Location data model from datawilayah.com API
String _toTitleCase(String s) {
  if (s.isEmpty) return s;
  return s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class Province {
  const Province({required this.code, required this.name});
  final String code;
  final String name;

  factory Province.fromJson(Map<String, dynamic> json) {
    final nama = json['nama_wilayah'] as String? ?? '';
    final kode = json['kode_wilayah']?.toString() ?? '';
    return Province(code: kode, name: _toTitleCase(nama));
  }
}

class City {
  const City({
    required this.code,
    required this.name,
    required this.provinceCode,
    required this.provinceName,
  });
  final String code;
  final String name;
  final String provinceCode;
  final String provinceName;

  /// City name ready for Aladhan API (without KAB./KOTA prefix)
  String get cityNameForPrayer {
    String n = name.trim();
    final upper = n.toUpperCase();
    if (upper.startsWith('KAB. ')) n = n.substring(5).trim();
    if (upper.startsWith('KOTA ')) n = n.substring(5).trim();
    return _toTitleCase(n);
  }

  factory City.fromJson(Map<String, dynamic> json) {
    final nama = json['nama_wilayah'] as String? ?? '';
    final kode = json['kode_wilayah']?.toString() ?? '';
    final kodeProv = json['kode_provinsi']?.toString() ?? '';
    final namaProv = json['nama_provinsi'] as String? ?? '';
    return City(
      code: kode,
      name: nama,
      provinceCode: kodeProv,
      provinceName: _toTitleCase(namaProv),
    );
  }
}
