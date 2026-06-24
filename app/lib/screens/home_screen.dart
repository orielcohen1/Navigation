import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/poi.dart';
import '../state/app_state.dart';
import 'qr_scan_screen.dart';
import 'map_screen.dart';
import 'ar_screen.dart';

/// Entry screen: POI search + quick-access buttons.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;
  int _bottomNavIndex = 0; // 0 = Search, 1 = Map, 2 = AR

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openQRScan() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QRScanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (appState.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (appState.error != null) {
      return Scaffold(
        body: Center(
          child: Text(appState.error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final body = _bottomNavIndex == 1
        ? const MapScreen()
        : _bottomNavIndex == 2
            ? const ARScreen()
            : _buildSearchBody(appState);

    return Scaffold(
      appBar: AppBar(
        title: Text(appState.mallData?.name ?? 'Indoor Nav'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan location QR',
            onPressed: _openQRScan,
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomNavIndex,
        onDestinationSelected: (i) => setState(() => _bottomNavIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.camera_alt), label: 'AR'),
        ],
      ),
    );
  }

  Widget _buildSearchBody(AppState appState) {
    final allPois = appState.mallData?.searchPOIs(_query) ?? [];
    final pois = _selectedCategory == null
        ? allPois
        : allPois.where((p) => p.category == _selectedCategory).toList();
    final categories = (appState.mallData?.pois ?? [])
        .map((p) => p.category)
        .toSet()
        .toList()
      ..sort();

    return Column(
      children: [
        // ── Location status banner ──────────────────────────────────────────
        _LocationBanner(onScanTap: _openQRScan),

        // ── Search bar ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search stores, food, services…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
          ),
        ),

        // ── Category filter chips ───────────────────────────────────────────
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                ),
              ),
              ...categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: _selectedCategory == cat,
                      onSelected: (_) => setState(() =>
                          _selectedCategory = _selectedCategory == cat ? null : cat),
                    ),
                  )),
            ],
          ),
        ),

        // ── POI list ───────────────────────────────────────────────────────
        Expanded(
          child: pois.isEmpty
              ? const Center(child: Text('No results found.'))
              : ListView.builder(
                  itemCount: pois.length,
                  itemBuilder: (_, i) => _POITile(
                    poi: pois[i],
                    onShowMap: () => setState(() => _bottomNavIndex = 1),
                  ),
                ),
        ),
      ],
    );
  }
}

class _LocationBanner extends StatelessWidget {
  final VoidCallback onScanTap;
  const _LocationBanner({required this.onScanTap});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Arrived state
    if (appState.hasArrived) {
      return Container(
        color: Colors.green.shade100,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You\'ve arrived at ${appState.destination!.name}!',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(
              onPressed: appState.clearDestination,
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }

    if (appState.hasLocation) {
      final locationName = appState.currentLocationName;
      return Container(
        color: Colors.green.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.location_on, color: Colors.green.shade700, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.green.shade800, fontSize: 13),
                  children: [
                    const TextSpan(text: 'You are at '),
                    TextSpan(
                      text: locationName ?? 'known location',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ' — tap a destination below'),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onScanTap,
      child: Container(
        color: Colors.amber.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.amber.shade800, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Scan a QR code to set your location',
                style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.amber.shade700),
          ],
        ),
      ),
    );
  }
}

class _POITile extends StatelessWidget {
  final POI poi;
  final VoidCallback onShowMap;
  const _POITile({required this.poi, required this.onShowMap});

  @override
  Widget build(BuildContext context) {
    // context.watch so isSelected updates live when destination changes
    final appState = context.watch<AppState>();
    final isSelected = appState.destination?.id == poi.id;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isSelected ? Colors.blue.shade600 : Colors.grey.shade200,
        child: Icon(
          _iconFor(poi.icon),
          color: isSelected ? Colors.white : Colors.grey.shade700,
          size: 20,
        ),
      ),
      title: Text(poi.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${poi.category} · ${poi.floorId == "G" ? "Ground Floor" : "Upper Floor"}'),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.blue)
          : const Icon(Icons.chevron_right),
      onTap: () {
        appState.setDestination(poi);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigating to ${poi.name}'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(label: 'Map', onPressed: onShowMap),
          ),
        );
      },
    );
  }

  IconData _iconFor(String name) {
    const map = {
      'restaurant': Icons.restaurant,
      'local_cafe': Icons.local_cafe,
      'fastfood': Icons.fastfood,
      'shopping_cart': Icons.shopping_cart,
      'local_pharmacy': Icons.local_pharmacy,
      'account_balance': Icons.account_balance,
      'info': Icons.info,
      'movie': Icons.movie,
      'checkroom': Icons.checkroom,
      'phone_iphone': Icons.phone_iphone,
      'directions_run': Icons.directions_run,
      'child_care': Icons.child_care,
    };
    return map[name] ?? Icons.place;
  }
}
