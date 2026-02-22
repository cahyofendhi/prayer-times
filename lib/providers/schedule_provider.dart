import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/prayer_time.dart';
import '../models/location.dart';
import '../services/prayer_api_service.dart';
import '../services/location_api_service.dart';

/// Prayer times and location state
class ScheduleState {
  const ScheduleState({
    this.provinces = const [],
    this.cities = const [],
    this.selectedProvince,
    this.selectedCity,
    this.useCurrentLocation = true,
    this.currentLat,
    this.currentLng,
    this.isLoadingRegion = true,
    this.regionError,
    this.selectedDate,
    this.isLoadingPrayer = false,
    this.prayerError,
    this.todayPrayer,
  });

  final List<Province> provinces;
  final List<City> cities;
  final Province? selectedProvince;
  final City? selectedCity;
  final bool useCurrentLocation;
  final double? currentLat;
  final double? currentLng;
  final bool isLoadingRegion;
  final String? regionError;
  final DateTime? selectedDate;
  final bool isLoadingPrayer;
  final String? prayerError;
  final PrayerTime? todayPrayer;

  DateTime get selectedDateOrNow => selectedDate ?? DateTime.now();

  ScheduleState copyWith({
    List<Province>? provinces,
    List<City>? cities,
    Province? selectedProvince,
    City? selectedCity,
    bool? useCurrentLocation,
    double? currentLat,
    double? currentLng,
    bool? isLoadingRegion,
    Object? regionError = _sentinel,
    DateTime? selectedDate,
    bool? isLoadingPrayer,
    Object? prayerError = _sentinel,
    PrayerTime? todayPrayer,
  }) {
    return ScheduleState(
      provinces: provinces ?? this.provinces,
      cities: cities ?? this.cities,
      selectedProvince: selectedProvince ?? this.selectedProvince,
      selectedCity: selectedCity ?? this.selectedCity,
      useCurrentLocation: useCurrentLocation ?? this.useCurrentLocation,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      isLoadingRegion: isLoadingRegion ?? this.isLoadingRegion,
      regionError: identical(regionError, _sentinel) ? this.regionError : regionError as String?,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoadingPrayer: isLoadingPrayer ?? this.isLoadingPrayer,
      prayerError: identical(prayerError, _sentinel) ? this.prayerError : prayerError as String?,
      todayPrayer: todayPrayer ?? this.todayPrayer,
    );
  }
}

const _sentinel = Object();

class ScheduleNotifier extends Notifier<ScheduleState> {
  @override
  ScheduleState build() {
    return ScheduleState(selectedDate: DateTime.now());
  }

  /// Call once when app/screen first loads
  void initLoad() {
    loadProvinces();
    _loadCurrentLocationAndPrayer();
  }

  PrayerApiService get _api => ref.read(prayerApiServiceProvider);
  LocationApiService get _location => ref.read(locationApiServiceProvider);

  Future<Position?> _getCurrentPosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadCurrentLocationAndPrayer() async {
    final pos = await _getCurrentPosition();
    if (pos == null) return;
    state = state.copyWith(
      currentLat: pos.latitude,
      currentLng: pos.longitude,
      useCurrentLocation: true,
    );
    loadPrayerTimes();
  }

  Future<void> loadProvinces() async {
    state = state.copyWith(isLoadingRegion: true, regionError: null);
    try {
      final list = await _location.getProvinces();
      state = state.copyWith(provinces: list, isLoadingRegion: false);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        regionError: msg.isNotEmpty ? msg : 'Failed to load region data',
        isLoadingRegion: false,
      );
    }
  }

  Future<void> loadCities(String provinceCode) async {
    state = state.copyWith(cities: []);
    try {
      final list = await _location.getCitiesByProvinceCode(provinceCode);
      state = state.copyWith(cities: list);
    } catch (_) {
      state = state.copyWith(cities: []);
    }
  }

  Future<Position?> getCurrentPosition() => _getCurrentPosition();

  Future<void> loadPrayerTimes() async {
    state = state.copyWith(isLoadingPrayer: true, prayerError: null);
    try {
      if (state.useCurrentLocation &&
          state.currentLat != null &&
          state.currentLng != null) {
        final result = await _api.getPrayerTimeByCoordinates(
          latitude: state.currentLat!,
          longitude: state.currentLng!,
          date: state.selectedDateOrNow,
        );
        state = state.copyWith(
            todayPrayer: result, isLoadingPrayer: false, prayerError: null);
        return;
      }
      if (state.selectedCity != null) {
        final result = await _api.getPrayerTime(
          city: state.selectedCity!.cityNameForPrayer,
          date: state.selectedDateOrNow,
        );
        state = state.copyWith(
            todayPrayer: result, isLoadingPrayer: false, prayerError: null);
        return;
      }
      state = state.copyWith(isLoadingPrayer: false);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        prayerError: msg.isNotEmpty ? msg : 'Failed to load prayer times',
        isLoadingPrayer: false,
      );
    }
  }

  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
    loadPrayerTimes();
  }

  void setUseCurrentLocation(Position pos) {
    state = state.copyWith(
      useCurrentLocation: true,
      currentLat: pos.latitude,
      currentLng: pos.longitude,
      selectedProvince: null,
      selectedCity: null,
    );
    loadPrayerTimes();
  }

  void setSelectedCity(Province province, City city) {
    state = state.copyWith(
      useCurrentLocation: false,
      selectedProvince: province,
      selectedCity: city,
    );
    loadCities(province.code);
    loadPrayerTimes();
  }
}

final scheduleProvider =
    NotifierProvider<ScheduleNotifier, ScheduleState>(ScheduleNotifier.new);
