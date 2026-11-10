import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/location.dart';
import '../services/route_provider.dart';
import '../widgets/location_card.dart';
import '../widgets/route_timeline.dart';
import '../widgets/add_location_dialog.dart';
import '../widgets/google_map_widget.dart';
import '../widgets/journey_progress_card.dart';
import '../widgets/journey_settings_sheet.dart';
import '../widgets/journey_status_card.dart';
import '../widgets/arrival_bottom_sheet.dart';
import '../models/journey_settings.dart';
import '../services/navigation_service.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _homePromptShown = false;
  bool _isTopPanelExpanded = true;

  @override
  void initState() {
    super.initState();
    // 3 Tabs: Map, Stops List, Directions
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showHomeChoiceDialog(BuildContext context) async {
    final provider = Provider.of<RouteProvider>(context, listen: false);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.home_outlined, size: 40, color: AppColors.homeMarker),
          title: const Text('Set Home Location'),
          content: const Text(
            'To start optimizing routes, please set your starting home location.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsOverflowButtonSpacing: 8,
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.gps_fixed),
              label: const Text('Use Current Location'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close choice dialog
                
                // Show loading indicator
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingContext) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                final success = await provider.setHomeToCurrentLocation();
                
                if (mounted) {
                  Navigator.of(context).pop(); // Close loading indicator
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Home updated from current location.' : 'Unable to get current location.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  if (!success) {
                    // Reopen search dialog on failure so they can type it
                    _showAddLocationDialog(context, isSettingHome: true);
                  }
                }
              },
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(220, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.search),
              label: const Text('Type & Search Address'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close choice dialog
                _showAddLocationDialog(context, isSettingHome: true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddLocationDialog(BuildContext context, {bool isSettingHome = false}) async {
    final result = await showDialog<Location>(
      context: context,
      builder: (context) => AddLocationDialog(isSettingHome: isSettingHome),
    );

    if (result != null && mounted) {
      final provider = Provider.of<RouteProvider>(context, listen: false);
      if (isSettingHome) {
        await provider.updateHome(result);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Home location updated successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await provider.addStop(result);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${result.name}" added to route stops.'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Optimize',
              onPressed: () => provider.optimizeRoute(),
            ),
          ),
        );
      }
    }
  }

  void _showHomeOptionsDialog(BuildContext context) {
    final provider = Provider.of<RouteProvider>(context, listen: false);
    final home = provider.home;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.home, color: AppColors.homeMarker),
            SizedBox(width: 8),
            Text('Home Base Location'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (home.id != 'unset_home') ...[
              Text(
                'Current Address:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                home.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Divider(height: 24),
            ],
            ListTile(
              leading: const Icon(Icons.gps_fixed, color: AppColors.primary),
              title: const Text('Use Current Location'),
              subtitle: const Text('Locate using GPS device', style: TextStyle(fontSize: 11)),
              onTap: () async {
                Navigator.of(dialogContext).pop();
                
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                final success = await provider.setHomeToCurrentLocation();
                
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Home updated from current location.' : 'Unable to get current location.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Change Home Address'),
              subtitle: const Text('Search for a new location', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.of(dialogContext).pop();
                _showAddLocationDialog(context, isSettingHome: true);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 120,
        leading: Consumer<RouteProvider>(
          builder: (context, provider, child) => Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showHomeOptionsDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (isDark ? Colors.white24 : Colors.black12),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.home, color: AppColors.homeMarker, size: 12),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          provider.home.id == 'unset_home' 
                              ? 'Set Home' 
                              : provider.home.name.split(',')[0],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 1),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Image.asset(
          isDark ? 'assets/logo/logo_wordmark_dark.png' : 'assets/logo/logo_wordmark.png',
          height: 26,
          fit: BoxFit.contain,
        ),
        actions: [
          // Theme Toggle
          Consumer<RouteProvider>(
            builder: (context, provider, child) => IconButton(
              icon: Icon(
                provider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
              tooltip: provider.isDarkMode ? 'Light Mode' : 'Dark Mode',
              onPressed: () => provider.toggleTheme(),
            ),
          ),
          
          // Overflow Menu
          PopupMenuButton<String>(
            onSelected: (value) {
              final provider = Provider.of<RouteProvider>(context, listen: false);
              if (value == 'clear') {
                provider.clearStops();
              } else if (value == 'home') {
                _showAddLocationDialog(context, isSettingHome: true);
              } else if (value == 'settings') {
                JourneySettingsSheet.show(context);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'home',
                child: Row(
                  children: [
                    Icon(Icons.home_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Edit Home Location'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Journey Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Text('Clear Stops', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<RouteProvider>(
        builder: (context, provider, child) {
          if (provider.hasArrivedAtDestination) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.dismissArrivalNotification();
              ArrivalBottomSheet.show(context);
            });
          }

          if (provider.locationTrackerError != null) {
            final err = provider.locationTrackerError!;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.clearLocationTrackerError();
              _showTrackerErrorDialog(context, err);
            });
          }

          if (provider.isInitialized && !_homePromptShown && provider.home.id == 'unset_home') {
            _homePromptShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showHomeChoiceDialog(context);
              }
            });
          }

          final activeRoute = provider.activeRoute;
          final home = provider.home;
          final isOptimized = provider.isOptimized;
          final totalDistance = provider.routePolylines.isNotEmpty ? provider.routeDistanceKm : provider.totalDistance;
          final goingDistance = provider.goingDistanceKm;
          final returnDistance = provider.returnDistanceKm;
          final totalTime = provider.routePolylines.isNotEmpty ? provider.routeDuration : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dashboard Metrics Header or Journey Progress Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: provider.journeyState.isJourneyActive
                    ? JourneyProgressCard(
                        journeyState: provider.journeyState,
                        onCancel: () => provider.cancelJourney(),
                        isExpanded: _isTopPanelExpanded,
                        onToggleExpand: () => setState(() => _isTopPanelExpanded = !_isTopPanelExpanded),
                      )
                    : _isTopPanelExpanded
                        ? Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [AppColors.surfaceDark, const Color(0xFF1E293B)]
                                    : [Colors.white, const Color(0xFFF1F5F9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  child: Column(
                                    children: [
                                      // Metrics layout
                                      Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              _buildMetric(
                                                context,
                                                title: 'STOPS',
                                                value: '${activeRoute.length}',
                                                icon: Icons.location_on_outlined,
                                                color: AppColors.secondary,
                                              ),
                                              _buildMetric(
                                                context,
                                                title: 'TOTAL DISTANCE',
                                                value: '${totalDistance.toStringAsFixed(1)} km',
                                                icon: Icons.directions_car_outlined,
                                                color: AppColors.primary,
                                              ),
                                              _buildMetric(
                                                context,
                                                title: 'TRAVEL TIME',
                                                value: totalTime != null ? _formatDuration(totalTime) : _formatEstTime(totalDistance),
                                                icon: Icons.speed_outlined,
                                                color: AppColors.accent,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          const Divider(height: AppSpacing.md, thickness: 0.5),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              _buildMetric(
                                                context,
                                                title: 'GOING DISTANCE (UP)',
                                                value: '${goingDistance.toStringAsFixed(1)} km',
                                                icon: Icons.arrow_upward_rounded,
                                                color: AppColors.secondary,
                                              ),
                                              _buildMetric(
                                                context,
                                                title: 'RETURN DISTANCE (DOWN)',
                                                value: '${returnDistance.toStringAsFixed(1)} km',
                                                icon: Icons.arrow_downward_rounded,
                                                color: AppColors.accent,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Optimization button/banner
                                      if (activeRoute.isNotEmpty) ...[
                                        const SizedBox(height: AppSpacing.md),
                                        if (!isOptimized)
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                              ),
                                            ).copyWith(
                                              elevation: WidgetStateProperty.all(0),
                                            ),
                                            icon: const SizedBox.shrink(),
                                            label: Ink(
                                              decoration: BoxDecoration(
                                                gradient: AppColors.primaryGradient,
                                                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                              ),
                                              child: Container(
                                                alignment: Alignment.center,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                child: const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.auto_awesome, color: Colors.white),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Optimize Route Sequence',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            onPressed: () {
                                              provider.optimizeRoute();
                                              ScaffoldMessenger.of(context).clearSnackBars();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Route optimized! Home-to-Home route created.'),
                                                  behavior: SnackBarBehavior.floating,
                                                  backgroundColor: AppColors.visited,
                                                ),
                                              );
                                            },
                                          )
                                        else ...[
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.verified, color: AppColors.visited, size: 16),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Sequence Optimized (Shortest Loop)',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: AppColors.visited,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                              ),
                                            ).copyWith(
                                              elevation: WidgetStateProperty.all(0),
                                            ),
                                            icon: const SizedBox.shrink(),
                                            label: Ink(
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                              ),
                                              child: Container(
                                                alignment: Alignment.center,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                child: const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.play_circle_fill, color: Colors.white),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Start Journey',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            onPressed: (home.id != 'unset_home' && activeRoute.isNotEmpty)
                                                ? () => provider.startJourney()
                                                : null,
                                          ),
                                        ],
                                      ],
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Collapse Dashboard',
                                    onPressed: () => setState(() => _isTopPanelExpanded = false),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: isDark ? AppColors.surfaceDark : Colors.white,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.alt_route_rounded, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${activeRoute.length} stops • ${totalDistance.toStringAsFixed(1)} km (Go: ${goingDistance.toStringAsFixed(1)} km, Ret: ${returnDistance.toStringAsFixed(1)} km)',
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Expand Dashboard',
                                    onPressed: () => setState(() => _isTopPanelExpanded = true),
                                  ),
                                ],
                              ),
                            ),
                          ),
              ),

              // TabBar Navigation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    tabs: const [
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.map_outlined, size: 16), SizedBox(width: 6), Text('Map')])),
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.format_list_bulleted, size: 16), SizedBox(width: 6), Text('Stops')])),
                      Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.timeline, size: 16), SizedBox(width: 6), Text('Timeline')])),
                    ],
                  ),
                ),
              ),

              // Tab contents
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Map Visualizer
                    _buildMapTab(context, home, activeRoute, isDark),

                    // Tab 2: Stops List (Reorderable)
                    _buildStopsTab(context, activeRoute, provider),

                    // Tab 3: Route Timeline
                    _buildTimelineTab(context, home, activeRoute),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<RouteProvider>(
        builder: (context, provider, child) => provider.journeyState.isJourneyActive
            ? const SizedBox.shrink()
            : FloatingActionButton(
                onPressed: () => _showAddLocationDialog(context),
                tooltip: 'Add Stop',
                child: const Icon(Icons.add_location_alt),
              ),
      ),
      bottomNavigationBar: Consumer<RouteProvider>(
        builder: (context, provider, child) {
          final state = provider.journeyState;
          if (!state.isJourneyActive) return const SizedBox.shrink();

          final isCompleted = state.currentStopIndex >= provider.stops.length;

          if (isCompleted) {
            final startTime = state.journeyStartTime;
            final duration = startTime != null ? DateTime.now().difference(startTime) : Duration.zero;
            final durationText = _formatDuration(duration);

            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? AppColors.surfaceDark : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: theme.brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.celebration, color: AppColors.accent, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'All destinations completed 🎉',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(context, 'Stops Completed', '${state.completedStops.length}'),
                        _buildStatItem(context, 'Total Distance', '${state.totalDistance.toStringAsFixed(1)} km'),
                        _buildStatItem(context, 'Total Time', durationText),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                              ),
                            ),
                            icon: const Icon(Icons.home),
                            label: const Text('Return Home', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              NavigationService.navigateTo(provider.home.latitude, provider.home.longitude);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                              ),
                            ),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Finish Journey', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              provider.cancelJourney();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                top: BorderSide(
                  color: theme.brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Next Stop: ${state.currentDestination?.name ?? ""}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                            ),
                          ),
                          icon: const Icon(Icons.navigation),
                          label: const Text(
                            'Navigate',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          onPressed: () {
                            final dest = state.currentDestination;
                            if (dest != null) {
                              NavigationService.navigateTo(dest.latitude, dest.longitude);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.visited,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                            ),
                          ),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Visited', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            provider.completeActiveStop();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orangeAccent,
                            side: const BorderSide(color: Colors.orangeAccent),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                            ),
                          ),
                          icon: const Icon(Icons.skip_next, size: 16),
                          label: const Text('Skip', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            provider.skipActiveStop();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: theme.brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  String _formatEstTime(double distanceKm) {
    if (distanceKm == 0) return '0m';
    // Assume average transit speed of 40 km/h
    final totalHours = distanceKm / 40.0;
    final totalMinutes = (totalHours * 60).round();

    if (totalMinutes < 60) {
      return '${totalMinutes}m';
    } else {
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }

  Widget _buildMapTab(
    BuildContext context,
    Location home,
    List<Location> activeRoute,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Google Maps Visualizer
            Positioned.fill(
              child: const GoogleMapWidget(),
            ),

            // Journey Status Card overlay
            Positioned(
              top: 12,
              right: 12,
              width: 320,
              child: const JourneyStatusCard(),
            ),
            
            // Legend Trigger Button (Permanently visible at top-left)
            Positioned(
              top: 12,
              left: 12,
              child: FloatingActionButton.small(
                heroTag: 'map_legend_button',
                backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
                child: const Icon(Icons.info_outline, size: 20),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Row(
                        children: [
                          Icon(Icons.explore_outlined, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Map Color Legend'),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem(context, label: 'Home Base', color: AppColors.homeMarker),
                          const SizedBox(height: 8),
                          _buildLegendItem(context, label: 'Active Destination', color: Colors.orange),
                          const SizedBox(height: 8),
                          _buildLegendItem(context, label: 'Pending Stop', color: AppColors.primary),
                          const SizedBox(height: 8),
                          _buildLegendItem(context, label: 'Visited Stop', color: AppColors.visited),
                          const SizedBox(height: 8),
                          _buildLegendItem(context, label: 'Your Location', color: Colors.purpleAccent),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, {required String label, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildStopsTab(
    BuildContext context,
    List<Location> activeRoute,
    RouteProvider provider,
  ) {
    if (activeRoute.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_location_outlined,
                size: 64,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondaryDark.withOpacity(0.3)
                    : AppColors.textSecondaryLight.withOpacity(0.3),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No stops in this route.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add stops using the button below or edit home from the top-right menu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ReorderableListView.builder(
        itemCount: activeRoute.length,
        header: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Drag and drop stops to reorder, or click Optimize above.',
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        itemBuilder: (context, index) {
          final location = activeRoute[index];
          final isActive = provider.journeyState.isJourneyActive &&
              provider.journeyState.currentDestination?.id == location.id;
          return LocationCard(
            cardKey: ValueKey(location.id),
            location: location,
            index: index,
            onDelete: () => provider.removeStop(location.id),
            onToggleVisited: () => provider.toggleVisited(location.id),
            isActive: isActive,
          );
        },
        onReorder: (oldIndex, newIndex) => provider.reorderStops(oldIndex, newIndex),
      ),
    );
  }

  Widget _buildTimelineTab(
    BuildContext context,
    Location home,
    List<Location> activeRoute,
  ) {
    final provider = Provider.of<RouteProvider>(context, listen: false);
    final activeStopId = provider.journeyState.isJourneyActive
        ? provider.journeyState.currentDestination?.id
        : null;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SingleChildScrollView(
        child: RouteTimeline(
          home: home,
          optimizedRoute: activeRoute,
          activeStopId: activeStopId,
        ),
      ),
    );
  }

  void _showTrackerErrorDialog(BuildContext context, String errorCode) {
    String title;
    String message;
    IconData icon;
    Color color;

    switch (errorCode) {
      case 'GPS_DISABLED':
        title = 'GPS Service Disabled';
        message = 'Please enable location services in your system settings to support automatic arrival detection.';
        icon = Icons.gps_off;
        color = Colors.redAccent;
        break;
      case 'PERMISSION_DENIED':
        title = 'Location Permission Denied';
        message = 'Location access is required to track your progress and detect arrivals. Please grant permission.';
        icon = Icons.location_off;
        color = Colors.orangeAccent;
        break;
      case 'PERMISSION_PERMANENTLY_DENIED':
        title = 'Location Permission Blocked';
        message = 'Location permission is permanently denied. Please enable it in system settings to run tracking.';
        icon = Icons.block;
        color = Colors.red;
        break;
      case 'LOCATION_TIMEOUT':
        title = 'GPS Signal Timeout';
        message = 'Getting your GPS position is taking longer than usual. Please check your signal or move to an open space.';
        icon = Icons.timer_off;
        color = Colors.amber;
        break;
      default:
        title = 'Location Tracking Error';
        message = errorCode;
        icon = Icons.error_outline;
        color = Colors.redAccent;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(icon, color: color, size: 40),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
