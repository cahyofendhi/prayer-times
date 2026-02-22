import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/location.dart';
import '../providers/schedule_provider.dart';
import '../services/location_api_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scheduleProvider.notifier).initLoad();
    });
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  void _showSearchDialog<T>({
    required BuildContext context,
    required String title,
    required String hintSearch,
    required List<T> items,
    required T? selected,
    required String Function(T) itemLabel,
    required bool Function(T, String) itemMatch,
    required void Function(T?) onSelected,
  }) {
    var searchQuery = '';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final q = searchQuery.trim().toLowerCase();
          final filtered = q.isEmpty
              ? items
              : items.where((e) => itemMatch(e, q)).toList();
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: hintSearch,
                      prefixIcon: const Icon(Icons.search, size: 22),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onChanged: (v) => setDialogState(() => searchQuery = v),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isSelected = selected != null &&
                            itemLabel(selected) == itemLabel(item);
                        return ListTile(
                          title: Text(itemLabel(item)),
                          selected: isSelected,
                          leading: isSelected
                              ? const Icon(Icons.check,
                                  color: Color(0xFF2E7D32), size: 22)
                              : null,
                          onTap: () {
                            onSelected(item);
                            Navigator.pop(dialogContext);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, ScheduleNotifier notifier) async {
    final state = ref.read(scheduleProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDateOrNow,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('en'),
    );
    if (picked != null && picked != state.selectedDateOrNow && mounted) {
      notifier.setSelectedDate(picked);
    }
  }

  void _showLocationPicker(BuildContext context) {
    final state = ref.read(scheduleProvider);
    final notifier = ref.read(scheduleProvider.notifier);
    final locationService = ref.read(locationApiServiceProvider);

    bool tempUseCurrentLocation = state.useCurrentLocation;
    Province? tempProvince = state.selectedProvince;
    City? tempCity = state.selectedCity;
    List<City> modalCities = List.from(state.cities);
    var loadingCities = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Consumer(
        builder: (context, ref, _) {
          final currentState = ref.watch(scheduleProvider);
          return StatefulBuilder(
            builder: (context, setModalState) {
              return DraggableScrollableSheet(
                initialChildSize: 0.65,
                minChildSize: 0.3,
                maxChildSize: 0.92,
                builder: (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Text(
                          'Select Location',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B5E20),
                              ),
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: tempUseCurrentLocation
                              ? const Color(0xFF2E7D32).withOpacity(0.12)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => setModalState(() {
                              tempUseCurrentLocation = true;
                              tempProvince = null;
                              tempCity = null;
                            }),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.my_location,
                                    color: tempUseCurrentLocation
                                        ? const Color(0xFF2E7D32)
                                        : Colors.grey,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Current location',
                                    style: TextStyle(
                                      fontWeight: tempUseCurrentLocation
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: tempUseCurrentLocation
                                          ? const Color(0xFF1B5E20)
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Or select province & city',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Province',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _showSearchDialog<Province>(
                              context: modalContext,
                              title: 'Select province',
                              hintSearch: 'Search province...',
                              items: currentState.provinces,
                              selected: tempProvince,
                              itemLabel: (p) => p.name,
                              itemMatch: (p, q) =>
                                  p.name.toLowerCase().contains(q),
                              onSelected: (p) async {
                                if (p == null) return;
                                setModalState(() {
                                  tempUseCurrentLocation = false;
                                  tempProvince = p;
                                  modalCities = [];
                                  tempCity = null;
                                  loadingCities = true;
                                });
                                final list = await locationService
                                    .getCitiesByProvinceCode(p.code);
                                if (!modalContext.mounted) return;
                                setModalState(() {
                                  modalCities = list;
                                  tempCity =
                                      list.isNotEmpty ? list.first : null;
                                  loadingCities = false;
                                });
                              },
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      currentState.isLoadingRegion
                                          ? 'Loading...'
                                          : (tempProvince?.name ?? 'Select province'),
                                      style: TextStyle(
                                        color: tempProvince != null
                                            ? Colors.black87
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'City',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: loadingCities
                                ? null
                                : () => _showSearchDialog<City>(
                                      context: modalContext,
                                      title: 'Select city',
                                      hintSearch: 'Search city...',
                                      items: modalCities,
                                      selected: tempCity,
                                      itemLabel: (c) => c.name,
                                      itemMatch: (c, q) =>
                                          c.name.toLowerCase().contains(q),
                                      onSelected: (c) {
                                        if (c != null) {
                                          setModalState(() {
                                            tempUseCurrentLocation = false;
                                            tempCity = c;
                                          });
                                        }
                                      },
                                    ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      tempCity?.name ?? 'Select city',
                                      style: TextStyle(
                                        color: tempCity != null
                                            ? Colors.black87
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () async {
                              if (tempUseCurrentLocation) {
                                final pos =
                                    await notifier.getCurrentPosition();
                                if (pos != null && context.mounted) {
                                  notifier.setUseCurrentLocation(pos);
                                  if (context.mounted) Navigator.pop(modalContext);
                                }
                                return;
                              }
                              final prov = tempProvince;
                              final city = tempCity;
                              if (city == null || prov == null) return;
                              notifier.setSelectedCity(prov, city);
                              Navigator.pop(modalContext);
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Apply'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleProvider);
    final notifier = ref.read(scheduleProvider.notifier);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF388E3C),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prayer Times',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _showLocationPicker(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  state.useCurrentLocation
                                      ? 'Current location'
                                      : (state.selectedCity != null &&
                                              state.selectedProvince != null
                                          ? '${state.selectedCity!.name}, ${state.selectedProvince!.name}'
                                          : 'Select location'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down,
                                    color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, notifier),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(state.selectedDateOrNow),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down,
                                    color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: _buildContent(context, state, notifier),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, ScheduleState state, ScheduleNotifier notifier) {
    if (state.isLoadingRegion) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF2E7D32)),
            SizedBox(height: 16),
            Text('Loading regions...'),
          ],
        ),
      );
    }

    if (state.regionError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                state.regionError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: notifier.loadProvinces,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final noLocation = !state.useCurrentLocation && state.selectedCity == null;
    final useGpsButNoCoords =
        state.useCurrentLocation && state.currentLat == null;
    if (noLocation || useGpsButNoCoords) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_outlined,
                  size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                useGpsButNoCoords
                    ? 'Enable location for prayer times at your position\nor select province and city below'
                    : 'Select province and city to view prayer times',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _showLocationPicker(context),
                icon: const Icon(Icons.place),
                label: const Text('Select location'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isLoadingPrayer) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF2E7D32)),
            SizedBox(height: 16),
            Text('Loading prayer times...'),
          ],
        ),
      );
    }

    if (state.prayerError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                state.prayerError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: notifier.loadPrayerTimes,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final today = state.todayPrayer;
    if (today == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No prayer times data',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: notifier.loadPrayerTimes,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload'),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              today.dateReadable,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          const SizedBox(height: 24),
          _buildPrayerCard('Imsak', today.imsak, Icons.nightlight_round),
          _buildPrayerCard('Fajr', today.fajr, Icons.wb_twilight),
          _buildPrayerCard('Sunrise', today.sunrise, Icons.wb_sunny_outlined),
          _buildPrayerCard('Dhuhr', today.dhuhr, Icons.wb_sunny),
          _buildPrayerCard('Asr', today.asr, Icons.brightness_6),
          _buildPrayerCard('Maghrib', today.maghrib, Icons.nightlight_round),
          _buildPrayerCard('Isha', today.isha, Icons.dark_mode),
        ],
      ),
    );
  }

  Widget _buildPrayerCard(String name, String time, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B5E20),
              ),
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}
