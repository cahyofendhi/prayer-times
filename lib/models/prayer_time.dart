/// Model untuk data jadwal sholat harian
class PrayerTime {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String imsak;
  final String dateReadable;

  const PrayerTime({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.imsak,
    required this.dateReadable,
  });

  factory PrayerTime.fromJson(Map<String, dynamic> json) {
    final timings = json['timings'] as Map<String, dynamic>;
    final date = json['date'] as Map<String, dynamic>;

    String parseTime(String value) {
      // Format dari API: "04:33 (WIB)" - ambil bagian waktu saja
      final match = RegExp(r'(\d{2}:\d{2})').firstMatch(value);
      return match?.group(1) ?? value;
    }

    return PrayerTime(
      fajr: parseTime(timings['Fajr'] ?? ''),
      sunrise: parseTime(timings['Sunrise'] ?? ''),
      dhuhr: parseTime(timings['Dhuhr'] ?? ''),
      asr: parseTime(timings['Asr'] ?? ''),
      maghrib: parseTime(timings['Maghrib'] ?? ''),
      isha: parseTime(timings['Isha'] ?? ''),
      imsak: parseTime(timings['Imsak'] ?? ''),
      dateReadable: date['readable'] ?? '',
    );
  }
}
