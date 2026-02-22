import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/location.dart';

/// Service to fetch province & city data from the datawilayah.com API
class LocationApiService {
  static const _baseUrl = 'https://api.datawilayah.com/api';

  Future<List<Province>> getProvinces() async {
    const url = '$_baseUrl/provinsi.json';
    final res = await _get(url);
    return _parseProvinces(res.body);
  }

  Future<List<City>> getCitiesByProvinceCode(String provinceCode) async {
    final url = '$_baseUrl/kabupaten_kota/$provinceCode.json';
    final res = await _get(url);
    return _parseCities(res.body);
  }

  List<Province> _parseProvinces(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final list = data['data'] as List?;
      if (list == null) return [];
      return list
          .map((e) => Province.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<City> _parseCities(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final list = data['data'] as List?;
      if (list == null) return [];
      return list
          .map((e) => City.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<http.Response> _get(String url) async {
    const timeout = Duration(seconds: 15);

    if (kIsWeb) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(timeout);
        if (res.statusCode == 200) return res;
      } catch (_) {}
      final proxyUrl =
          'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}';
      return http.get(Uri.parse(proxyUrl)).timeout(
            timeout,
            onTimeout: () =>
                throw Exception('Connection timeout. Check your internet.'),
          );
    }

    return http.get(Uri.parse(url)).timeout(
          timeout,
          onTimeout: () =>
              throw Exception('Koneksi timeout. Periksa internet.'),
        );
  }
}

final locationApiServiceProvider= Provider<LocationApiService>((ref) {
  return LocationApiService();
});
