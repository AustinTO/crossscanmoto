import 'package:flutter/material.dart';

import 'adapter_page.dart';
import 'app_navigation.dart';
import 'diagnostic_session.dart';
import 'diagnostics/dtc_database.dart';
import 'diagnostics/auto_scan_controller.dart';
import 'diagnostics/ecu_catalog.dart';
import 'diagnostics/protocol_setup.dart';
import 'diagnostics/service_manager.dart';
import 'diagnostics/vehicle_catalog.dart';
import 'ecu_detail_dialog.dart';
import 'live_data_page.dart';
import 'preferences_page.dart';
import 'recovered_actuator_panel.dart';
import 'service_coding_page.dart';

void main() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('*** FLUTTER ERROR ***: ${details.exceptionAsString()}');
    debugPrint(details.stack.toString());
  };
  runApp(const MotoDiagApp());
}

const _ink = Color(0xFF080A0B);
const _panel = Color(0xFF13181B);
const _lime = Color(0xFFBCEB58);
const _muted = Color(0xFF929B9B);
const _edge = Color(0xFF293133);

typedef MotoDiagApp = CrossScanMotoApp;

class CrossScanMotoApp extends StatelessWidget {
  const CrossScanMotoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CrossScan Moto',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: _lime,
            brightness: Brightness.dark,
            surface: _panel,
          ).copyWith(
            primary: _lime,
            onPrimary: _ink,
            secondary: _lime,
            outline: const Color(0xFF34403B),
          ),
      useMaterial3: true,
      fontFamily: 'Roboto',
      dividerColor: Colors.white.withValues(alpha: .08),
      scaffoldBackgroundColor: _ink,
      cardTheme: CardThemeData(
        color: _panel,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111718),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF34403B)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF34403B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _lime, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: _lime,
          foregroundColor: _ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: _lime,
          side: const BorderSide(color: Color(0xFF46514B)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: const Color(0xFF101416),
        indicatorColor: _lime.withValues(alpha: .13),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? _lime : _muted,
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    ),
    home: const DashboardPage(),
  );
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _tab = 0;
  final Set<int> _visitedTabs = {0};
  bool _showPreferences = false;

  @override
  Widget build(BuildContext context) {
    if (_showPreferences) {
      return PreferencesPage(
        onBack: () => setState(() => _showPreferences = false),
      );
    }

    final pages = [
      OverviewTab(
        onVehicleChanged: (model, year) {
          final session = DiagnosticSession.instance;
          if (model == null && year == null) {
            session.clearVehicleProfile();
          } else {
            session.updateVehicleProfile(model: model, year: year);
          }
        },
      ),
      const SystemsTab(),
      _visitedTabs.contains(2) ? const LiveDataPage() : const SizedBox.shrink(),
      _visitedTabs.contains(3)
          ? const ServiceCodingPage()
          : const SizedBox.shrink(),
      _visitedTabs.contains(4) ? const AdapterPage() : const SizedBox.shrink(),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onSettings: () {
                setState(() => _showPreferences = true);
              },
            ),
            Expanded(
              child: IndexedStack(index: _tab, children: pages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() {
          _visitedTabs.add(index);
          _tab = index;
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Garage',
          ),
          NavigationDestination(
            icon: Icon(Icons.memory_outlined),
            selectedIcon: Icon(Icons.memory),
            label: 'Systems',
          ),
          NavigationDestination(
            icon: Icon(Icons.speed_outlined),
            selectedIcon: Icon(Icons.speed),
            label: 'Live Data',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_circle_outlined),
            selectedIcon: Icon(Icons.build_circle),
            label: 'Workshop',
          ),
          NavigationDestination(
            icon: Icon(Icons.cable_outlined),
            selectedIcon: Icon(Icons.cable),
            label: 'Adapter',
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSettings});
  final VoidCallback onSettings;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 13, 18, 10),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            border: Border.all(color: _lime.withValues(alpha: .72), width: 1.2),
            borderRadius: BorderRadius.circular(12),
            color: _lime.withValues(alpha: .08),
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(11),
            child: Image.asset('assets/branding/app-icon.png', fit: BoxFit.cover, cacheWidth: 128)),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CROSSSCAN MOTO',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'BMW MOTORRAD • PUPHR LLC',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: 1.5,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF171D1F),
            border: Border.all(color: _edge),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            onPressed: onSettings,
            icon: const Icon(Icons.tune_rounded, size: 19),
            tooltip: 'Preferences',
            visualDensity: VisualDensity.compact,
            color: Colors.white70,
          ),
        ),
      ],
    ),
  );
}

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.onVehicleChanged});
  final void Function(String?, int?) onVehicleChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      return ListenableBuilder(
        listenable: DiagnosticSession.instance,
        builder: (context, _) {
          final session = DiagnosticSession.instance;
          final model = session.profile.modelName;
          final year = session.profile.modelYear;
          final isConnected = session.connected;
          final batteryVal = isConnected
              ? (session.voltage?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '—')
              : '—';
          final odoVal = session.profile.odometerKm != null
              ? '${session.profile.odometerKm}'
              : '—';
          final faultsCount = session.autoScan.totalFaults;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              wide ? 34 : 20,
              14,
              wide ? 34 : 20,
              32,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1160),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Greeting(),
                      const SizedBox(height: 23),
                      _BikeCard(
                        model: model,
                        year: year,
                        isConnected: isConnected,
                        onChanged: onVehicleChanged,
                      ),
                      const SizedBox(height: 25),
                      _SectionHeader(
                        title: 'AT A GLANCE',
                        trailing: session.connected
                            ? (session.identity ?? 'Adapter connected')
                            : 'Awaiting vehicle connection',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              icon: Icons.speed_rounded,
                              label: 'ODOMETER',
                              value: odoVal,
                              unit: odoVal == '—' ? '' : 'km',
                              caption: odoVal == '—'
                                  ? 'Awaiting vehicle read'
                                  : 'Cluster mileage reading',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              icon: Icons.battery_charging_full_rounded,
                              label: 'BATTERY',
                              value: batteryVal,
                              unit: batteryVal == '—' ? '' : 'V',
                              caption: isConnected
                                  ? 'Adapter measured'
                                  : 'Awaiting link',
                            ),
                          ),
                          if (wide) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                icon: Icons.warning_amber_rounded,
                                label: 'ACTIVE FAULTS',
                                value: isConnected ? '$faultsCount' : '—',
                                unit: isConnected ? 'DTCs' : '',
                                caption: !isConnected
                                    ? 'Awaiting vehicle scan'
                                    : faultsCount == 0
                                    ? 'All modules clean'
                                    : 'Attention required',
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 27),
                      const _SectionHeader(
                        title: 'DIAGNOSTICS',
                        trailing: '03 / TOOLS',
                      ),
                      const SizedBox(height: 12),
                      if (wide)
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _ActionTile(
                                icon: Icons.radar_rounded,
                                title: 'Scan control units',
                                subtitle: 'Fault codes and module status',
                                kind: DiagnosticKind.scan,
                                featured: true,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _ActionTile(
                                icon: Icons.build_outlined,
                                title: 'Service functions',
                                subtitle: 'Maintenance tasks & resets',
                                kind: DiagnosticKind.service,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _ActionTile(
                                icon: Icons.precision_manufacturing_outlined,
                                title: 'Actuator tests',
                                subtitle: 'Bi-directional component tests',
                                kind: DiagnosticKind.actuator,
                              ),
                            ),
                          ],
                        )
                      else ...const [
                        _ActionTile(
                          icon: Icons.radar_rounded,
                          title: 'Scan control units',
                          subtitle: 'Fault codes and module status',
                          kind: DiagnosticKind.scan,
                          featured: true,
                        ),
                        _ActionTile(
                          icon: Icons.build_outlined,
                          title: 'Service functions',
                          subtitle: 'Maintenance tasks & resets',
                          kind: DiagnosticKind.service,
                        ),
                        _ActionTile(
                          icon: Icons.precision_manufacturing_outlined,
                          title: 'Actuator tests',
                          subtitle: 'Bi-directional component tests',
                          kind: DiagnosticKind.actuator,
                        ),
                      ],
                      const SizedBox(height: 22),
                      const _SectionHeader(
                        title: 'SESSION HISTORY',
                        trailing: 'Activity log',
                      ),
                      const SizedBox(height: 12),
                      _SessionHistoryView(events: session.events),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _Greeting extends StatelessWidget {
  const _Greeting();
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'GARAGE  /  BMW MOTORRAD',
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 2,
          color: _lime,
          fontWeight: FontWeight.w800,
        ),
      ),
      SizedBox(height: 11),
      Text(
        'Your workshop,',
        style: TextStyle(
          fontSize: 32,
          letterSpacing: -.9,
          height: 1.05,
          fontWeight: FontWeight.w700,
        ),
      ),
      SizedBox(height: 3),
      Text(
        'ready when you are.',
        style: TextStyle(
          fontSize: 31,
          letterSpacing: -1,
          height: 1.08,
          color: Color(0xFF8D9694),
          fontWeight: FontWeight.w400,
        ),
      ),
    ],
  );
}

class _BikeCard extends StatelessWidget {
  const _BikeCard({
    required this.model,
    required this.year,
    required this.isConnected,
    required this.onChanged,
  });
  final String? model;
  final int? year;
  final bool isConnected;
  final void Function(String?, int?) onChanged;

  Future<void> _chooseVehicle(BuildContext context) async {
    var selectedModel = model;
    var selectedYear = year;
    final result = await showModalBottomSheet<(String?, int?)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              4,
              22,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your motorcycle',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose a model and model year from BMW Motorrad lineup.',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: selectedModel,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final m in BmwVehicleCatalog.models)
                      DropdownMenuItem(
                        value: m.name,
                        child: Text(m.name, overflow: TextOverflow.ellipsis),
                      ),
                    const DropdownMenuItem(
                      value: 'Other BMW Motorrad',
                      child: Text('Other BMW Motorrad'),
                    ),
                  ],
                  onChanged: (value) =>
                      setSheetState(() => selectedModel = value),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Model year',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      List.generate(32, (index) => DateTime.now().year - index)
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                          )
                          .toList(),
                  onChanged: (value) =>
                      setSheetState(() => selectedYear = value),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, (null, null)),
                        child: const Text('Clear vehicle'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, (
                          selectedModel,
                          selectedYear,
                        )),
                        child: const Text('Save vehicle'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null) onChanged(result.$1, result.$2);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 700;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _chooseVehicle(context),
          borderRadius: BorderRadius.circular(26),
          child: Ink(
            height: wide ? 270 : 242,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF202A2B),
                  Color(0xFF111719),
                  Color(0xFF121718),
                ],
              ),
              border: Border.all(color: const Color(0xFF35403E)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .24),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -55,
                    width: wide ? 430 : 280,
                    height: wide ? 330 : 250,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            _lime.withValues(alpha: .11),
                            _lime.withValues(alpha: .025),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(child: IgnorePointer(child: Stack(fit: StackFit.expand, children: [
                    Image.asset('assets/branding/motorcycle-hero.webp', fit: BoxFit.cover, alignment: Alignment.centerRight, cacheWidth: (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context)).clamp(512, 1774).round()),
                    DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                      colors: [const Color(0xFF101719).withValues(alpha: .96), const Color(0xFF101719).withValues(alpha: .78), const Color(0xFF101719).withValues(alpha: .35)],
                      stops: const [0, .50, 1]))),
                  ]))),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 28 : 21,
                      20,
                      wide ? 28 : 21,
                      17,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: _lime,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'MY MOTORCYCLE',
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 1.8,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFC4CECA),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.north_east_rounded,
                              size: 17,
                              color: Colors.white.withValues(alpha: .7),
                            ),
                          ],
                        ),
                        const Spacer(),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: wide ? 520 : constraints.maxWidth * .72,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'BMW MOTORRAD',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.6,
                                  color: _muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                model ?? 'Add your motorcycle',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: wide ? 35 : 27,
                                  letterSpacing: -1.1,
                                  height: 1.05,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Builder(
                                builder: (context) {
                                  final profile =
                                      DiagnosticSession.instance.profile;
                                  final modelObj = BmwVehicleCatalog.findByName(
                                    model,
                                  );
                                  final isAuto = profile.isAutoIdentified;
                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      if (isAuto)
                                        const _VehicleTag(
                                          text: 'AUTO-IDENTIFIED',
                                          color: _lime,
                                        ),
                                      if (profile.needsDisambiguation)
                                        const _VehicleTag(
                                          text: 'DISAMBIGUATION REQUIRED',
                                          color: Colors.amber,
                                        ),
                                      if (year != null)
                                        _VehicleTag(text: 'Model year $year'),
                                      if (year == null && !isAuto)
                                        const _VehicleTag(
                                          text: 'MODEL YEAR NOT SET',
                                        ),
                                      Text(
                                        modelObj != null
                                            ? '${modelObj.engineType} (${modelObj.displacementCc} cc)'
                                            : (model == null
                                                  ? 'Choose your bike'
                                                  : 'BMW Motorrad Profile'),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFADB6B2),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              isConnected
                                  ? Icons.link_rounded
                                  : Icons.link_off_rounded,
                              size: 16,
                              color: isConnected
                                  ? _lime
                                  : const Color(0xFFE7B66C),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'BMW MOTORRAD',
                                style: TextStyle(
                                  fontSize: 9,
                                  letterSpacing: 1.2,
                                  color: Color(0xFFD7D0C3),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isConnected ? 'CONNECTED' : 'NO ADAPTER',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8,
                                letterSpacing: 1,
                                color: isConnected
                                    ? _lime
                                    : const Color(0xFFE7B66C),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              model == null ? 'ADD BIKE' : 'EDIT PROFILE',
                              style: const TextStyle(
                                fontSize: 9,
                                letterSpacing: 1.3,
                                color: _lime,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: _lime,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _VehicleTag extends StatelessWidget {
  const _VehicleTag({required this.text, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color != null
          ? color!.withValues(alpha: .15)
          : Colors.white.withValues(alpha: .075),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(
        color: color != null
            ? color!.withValues(alpha: .35)
            : Colors.white.withValues(alpha: .07),
      ),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 8,
        letterSpacing: .75,
        color: color ?? const Color(0xFFD8E0DB),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.caption,
  });
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String caption;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .06)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: _lime),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.2,
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Text(
          caption,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});
  final String title;
  final String trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w800,
          color: Colors.white70,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          trailing,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Colors.white38),
        ),
      ),
    ],
  );
}

enum DiagnosticKind { scan, service, actuator }

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.kind,
    this.featured = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final DiagnosticKind kind;
  final bool featured;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      boxShadow: featured
          ? [
              BoxShadow(
                color: _lime.withValues(alpha: .045),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ]
          : null,
    ),
    child: Material(
      color: featured ? const Color(0xFF19201E) : const Color(0xFF14191B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: featured ? _lime.withValues(alpha: .24) : _edge,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => appPush(context, DiagnosticPage(kind: kind)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _lime.withValues(alpha: featured ? .15 : .075),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: featured ? _lime : const Color(0xFF9FA9A4),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: featured
                            ? Colors.white
                            : const Color(0xFFE1E5E2),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.3,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                featured
                    ? Icons.arrow_forward_rounded
                    : Icons.chevron_right_rounded,
                color: featured ? _lime : Colors.white38,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SessionHistoryView extends StatelessWidget {
  const _SessionHistoryView({required this.events});
  final List<String> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Row(
          children: [
            Icon(Icons.history, color: Colors.white38),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No sessions yet. Completed diagnostics will appear here.',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final event in events.reversed.take(4))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: _lime,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class SystemsTab extends StatefulWidget {
  const SystemsTab({super.key});
  @override
  State<SystemsTab> createState() => _SystemsTabState();
}

class _SystemsTabState extends State<SystemsTab> {
  EcuCategory? _categoryFilter;
  bool _onlyEquipped = true;

  @override
  Widget build(BuildContext context) {
    final controller = DiagnosticSession.instance.autoScan;
    final activeVehicle = DiagnosticSession.instance.profile.model;
    final allEcus = activeVehicle != null
        ? BmwEcuCatalog.forSeries(activeVehicle.seriesCode,
            platformId: activeVehicle.platformId)
        : BmwEcuCatalog.all;
    final equippedAddresses = activeVehicle?.primaryEcuAddresses.toSet();

    final baseList = (_onlyEquipped && equippedAddresses != null)
        ? allEcus
              .where(
                (e) =>
                    equippedAddresses.contains(e.standardUdsAddress) ||
                    controller.reports[e.standardUdsAddress]?.state ==
                        EcuScanState.responding,
              )
              .toList()
        : allEcus;

    final filtered = _categoryFilter == null
        ? baseList
        : baseList.where((e) => e.category == _categoryFilter).toList();

    return ListenableBuilder(
      listenable: Listenable.merge([controller, DiagnosticSession.instance]),
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Control units',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activeVehicle != null && _onlyEquipped
                        ? 'Showing onboard modules equipped on ${activeVehicle.name}.'
                        : 'Possible systems vary by motorcycle and equipment.',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              if (controller.isScanning)
                IconButton(
                  icon: const Icon(
                    Icons.stop_circle,
                    color: Colors.redAccent,
                    size: 28,
                  ),
                  tooltip: 'Cancel scan',
                  onPressed: controller.cancel,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Auto Scan Action Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_panel, Color(0xFF1D2826)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _lime.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _lime.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.radar, color: _lime, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Full Vehicle System Scan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            controller.isScanning
                                ? controller.currentStep
                                : 'Queries all candidate BMW control units for identification & fault codes.',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (controller.isScanning) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: controller.progress,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(_lime),
                      minHeight: 6,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed:
                      controller.isScanning ||
                          DiagnosticSession.instance.operationBusy ||
                          !DiagnosticSession.instance.connected
                      ? null
                      : () async {
                          final shared = DiagnosticSession.instance;
                          try {
                            await shared.runExclusive(() async {
                              shared.invalidateVehicleProtocol();
                              await controller.runAutoScan(
                                session: shared.elmSession,
                                adapterType: BmwUdsAdapterType.unknown,
                                seriesCode: shared.profile.model?.seriesCode,
                              );
                            });
                          } catch (error) {
                            shared.record('Scan failed: $error');
                          }
                        },
                  icon: Icon(
                    controller.isScanning ? Icons.sync : Icons.search_rounded,
                    size: 18,
                  ),
                  label: Text(
                    controller.isScanning
                        ? 'Scanning Modules…'
                        : 'Scan Control Units',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (activeVehicle != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _onlyEquipped,
                      label: Text('Equipped (${baseList.length})'),
                      onSelected: (val) => setState(() => _onlyEquipped = val),
                      backgroundColor: _panel,
                      selectedColor: _lime.withValues(alpha: 0.18),
                      checkmarkColor: _lime,
                      labelStyle: TextStyle(
                        color: _onlyEquipped ? _lime : Colors.white70,
                        fontSize: 11,
                        fontWeight: _onlyEquipped
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: _onlyEquipped ? _lime : Colors.white12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                _buildCatChip('All Systems', null),
                _buildCatChip('Powertrain', EcuCategory.powertrain),
                _buildCatChip('Chassis & ABS', EcuCategory.chassis),
                _buildCatChip('Cockpit', EcuCategory.cockpit),
                _buildCatChip('Body', EcuCategory.body),
                _buildCatChip('Security & TPMS', EcuCategory.security),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // List of ECUs
          for (final ecu in filtered) ...[
            Builder(
              builder: (context) {
                final report =
                    controller.reports[ecu.standardUdsAddress] ??
                    EcuScanReport(definition: ecu, state: EcuScanState.pending);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: report.hasFaults
                          ? Colors.redAccent.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Material(
                    color: _panel,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => EcuDetailSheet.show(context, report),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: report.hasFaults
                                    ? Colors.redAccent.withValues(alpha: 0.12)
                                    : _lime.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                ecu.icon,
                                color: report.hasFaults
                                    ? Colors.redAccent
                                    : _lime,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        ecu.germanAbbrev,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          ecu.hexAddress,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontFamily: 'monospace',
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    ecu.name,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStatusPill(report),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white38,
                                  size: 18,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCatChip(String label, EcuCategory? cat) {
    final selected = _categoryFilter == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _categoryFilter = cat),
        backgroundColor: _panel,
        selectedColor: _lime.withValues(alpha: 0.18),
        checkmarkColor: _lime,
        labelStyle: TextStyle(
          color: selected ? _lime : Colors.white70,
          fontSize: 11,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(color: selected ? _lime : Colors.white12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildStatusPill(EcuScanReport report) {
    if (report.state == EcuScanState.scanning) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2, color: _lime),
      );
    }

    if (report.hasFaults) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Text(
          '${report.dtcs.length} DTC',
          style: const TextStyle(
            color: Colors.redAccent,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (report.state == EcuScanState.responding) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _lime.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'NO FAULTS',
          style: TextStyle(
            color: _lime,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return const Text(
      'NOT SCANNED',
      style: TextStyle(
        fontSize: 8,
        letterSpacing: 0.8,
        color: Colors.white30,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class DiagnosticPage extends StatefulWidget {
  const DiagnosticPage({super.key, required this.kind});
  final DiagnosticKind kind;

  @override
  State<DiagnosticPage> createState() => _DiagnosticPageState();
}

class _DiagnosticPageState extends State<DiagnosticPage> {
  bool _busy = false;
  String? _error;
  List<String>? _faults;

  Future<void> _scanFaults() async {
    setState(() {
      _busy = true;
      _error = null;
      _faults = null;
    });
    try {
      final report = await DiagnosticSession.instance.readFaults();
      if (!mounted) return;
      setState(
        () => _faults = report.dtcs
            .map(
              (dtc) =>
                  '${BmwDtcDatabase.lookup(dtc.code, ecuKey: DiagnosticSession.instance.ecuDefinitionKey, statusByte: dtc.status).title} • 0x${dtc.code.toRadixString(16).padLeft(6, '0').toUpperCase()} • status 0x${dtc.status.toRadixString(16).padLeft(2, '0').toUpperCase()}',
            )
            .toList(),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearFaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear diagnostic trouble codes?'),
        content: const Text(
          'This sends a clear request to the connected ECU. Stored fault information may be lost. Continue only if you intend to clear codes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear codes'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await DiagnosticSession.instance.clearFaults();
      if (mounted) setState(() => _faults = const []);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, description, icon) = switch (widget.kind) {
      DiagnosticKind.scan => (
        'Control unit scan',
        'A scan needs a connected adapter and a configured motorcycle protocol. Or run a full system auto-scan.',
        Icons.search,
      ),
      DiagnosticKind.service => (
        'Service functions',
        'Maintenance and reset operations for BMW Motorrad modules.',
        Icons.build_outlined,
      ),
      DiagnosticKind.actuator => (
        'Actuator tests',
        'Bi-directional component tests for supported BMW Motorrad modules.',
        Icons.precision_manufacturing_outlined,
      ),
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListenableBuilder(
        listenable: DiagnosticSession.instance,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: .06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _lime.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: _lime),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    DiagnosticSession.instance.protocolReady
                        ? title
                        : 'Vehicle protocol configuration',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white60, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _AdapterStatusPanel(kind: widget.kind),
            const SizedBox(height: 14),
            ...switch (widget.kind) {
              DiagnosticKind.scan => [
                FilledButton.icon(
                  onPressed: !DiagnosticSession.instance.protocolReady || _busy
                      ? null
                      : _scanFaults,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(_busy ? 'Scanning…' : 'Read fault codes'),
                ),
              ],
              DiagnosticKind.service => [
                for (final item in BmwServiceManager.items.take(3))
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _panel,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.description,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: () async {
                            final res = await BmwServiceManager.execute(
                              item: item,
                              link: DiagnosticSession.instance.activeLink,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(res.message)),
                              );
                            }
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  ),
              ],
              DiagnosticKind.actuator => [
                const RecoveredActuatorPanel(),
              ],
            },
            if (widget.kind == DiagnosticKind.scan &&
                DiagnosticSession.instance.protocolReady)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _clearFaults,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear fault codes'),
                ),
              ),
            if (_faults != null)
              Container(
                margin: const EdgeInsets.only(top: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _faults!.isEmpty
                          ? 'No fault codes returned'
                          : 'Fault codes (${_faults!.length})',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (_faults!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final fault in _faults!)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Text(
                            fault,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.white70,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            _SessionEventPanel(events: DiagnosticSession.instance.events),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => appPush(context, const AdapterPage()),
              icon: const Icon(Icons.cable),
              label: const Text('Open adapter connection'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdapterStatusPanel extends StatefulWidget {
  const _AdapterStatusPanel({required this.kind});
  final DiagnosticKind kind;
  @override
  State<_AdapterStatusPanel> createState() => _AdapterStatusPanelState();
}

class _AdapterStatusPanelState extends State<_AdapterStatusPanel> {
  bool _reading = false;
  String? _error;

  Future<void> _readVoltage() async {
    setState(() {
      _reading = true;
      _error = null;
    });
    try {
      await DiagnosticSession.instance.readAdapterVoltage();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = DiagnosticSession.instance;
    if (!session.connected) {
      return const _InfoPanel(
        icon: Icons.link_off,
        text:
            'No adapter connected. Connect an adapter to view its reported identity and voltage. Vehicle diagnostics also require a configured ECU protocol.',
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: _lime, size: 18),
              const SizedBox(width: 8),
              const Text(
                'ADAPTER CONNECTED',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                session.identity ?? 'Identity unavailable',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Adapter reported voltage',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
              Text(
                session.voltage ?? 'Not measured',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _reading ? null : _readVoltage,
              icon: _reading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 17),
              label: Text(_reading ? 'Reading…' : 'Refresh adapter voltage'),
            ),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionEventPanel extends StatelessWidget {
  const _SessionEventPanel({required this.events});
  final List<String> events;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SESSION ACTIVITY',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.3,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 10),
        if (events.isEmpty)
          const Text(
            'Adapter and diagnostic activity will appear here.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        for (final event in events.reversed.take(6))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              event,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ),
      ],
    ),
  );
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFF20251E),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: _lime),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    ),
  );
}
