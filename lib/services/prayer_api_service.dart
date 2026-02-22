import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/prayer_time.dart';

// Service to fetch prayer times from the Aladhan API
/// Documentation: https://aladhan.com/prayer-times-api
/// Uses the Indonesian Ministry of Religious Affairs calculation method (method=20)
class PrayerApiService {
  static const String _baseUrl = 'https://api.aladhan.com/v1';

  /// Get prayer times for a given date (endpoint: /timingsByCity).
  /// Uses Indonesia Ministry of Religious Affairs method (method=20).
  Future<PrayerTime> getPrayerTime({
    required String city,
    DateTime? date,
  }) async {
    final d = date ?? DateTime.now();
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

    final apiUrl = Uri.parse('$_baseUrl/timingsByCity/$dateStr')
        .replace(queryParameters: {
      'city': city,
      'country': 'ID',
      'method': '20', // Indonesia Ministry of Religious Affairs
    }).toString();

    final response = await _fetch(apiUrl);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] == 200 && data['data'] != null) {
        final dayData = data['data'] as Map<String, dynamic>;
        return PrayerTime.fromJson(dayData);
      }
    }

    throw Exception(
        'Failed to load prayer times (${response.statusCode}). Please try again.');
  }

  /// Prayer times by coordinates (for current location)
  /// Endpoint: /timings/{date}?latitude=...&longitude=...&method=20
  Future<PrayerTime> getPrayerTimeByCoordinates({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) async {
    final d = date ?? DateTime.now();
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

    final apiUrl = Uri.parse('$_baseUrl/timings/$dateStr')
        .replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'method': '20',
    }).toString();

    final response = await _fetch(apiUrl);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] == 200 && data['data'] != null) {
        final dayData = data['data'] as Map<String, dynamic>;
        return PrayerTime.fromJson(dayData);
      }
    }

    throw Exception(
        'Failed to load prayer times (${response.statusCode}). Please try again.');
  }

  Future<http.Response> _fetch(String apiUrl) async {
    const timeout = Duration(seconds: 15);

    if (kIsWeb) {
      try {
        final res = await http.get(Uri.parse(apiUrl)).timeout(timeout);
        if (res.statusCode == 200) return res;
      } catch (_) {}

      final proxyUrl =
          'https://api.allorigins.win/raw?url=${Uri.encodeComponent(apiUrl)}';
      return http.get(Uri.parse(proxyUrl)).timeout(
            timeout,
            onTimeout: () =>
                throw Exception('Connection timeout. Check your internet.'),
          );
    }

    return http.get(Uri.parse(apiUrl)).timeout(
          timeout,
          onTimeout: () =>
              throw Exception('Connection timeout. Check your internet.'),
        );
  }

  /// Get monthly prayer times by city (endpoint: /calendarByCity)
  /// [city] city name in Indonesia (e.g. Jakarta, Surabaya, Bandung)
  Future<List<PrayerTime>> getMonthlyPrayerTimes({
    required String city,
    int? month,
    int? year,
  }) async {
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;

    final queryParams = {
      'city': city,
      'country': 'ID', // ISO 3166-1 alpha-2
      'method': '20', // Kementerian Agama RI
      'month': m.toString(),
      'year': y.toString(),
    };

    final apiUrl = Uri.parse('$_baseUrl/calendarByCity')
        .replace(queryParameters: queryParams)
        .toString();

    List<PrayerTime>? parseResponse(String body) {
      try {
        final data = jsonDecode(body) as Map<String, dynamic>;
        if (data['code'] == 200 && data['data'] != null) {
          final list = data['data'] as List;
          return list
              .map((e) => PrayerTime.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
      return null;
    }

    final response = await _fetch(apiUrl);

    if (response.statusCode == 200) {
      final result = parseResponse(response.body);
      if (result != null && result.isNotEmpty) return result;
    }

    throw Exception(
        'Failed to load monthly times (${response.statusCode}). Please try again.');
  }
}

final prayerApiServiceProvider = Provider<PrayerApiService>((ref) {
  return PrayerApiService();
});
