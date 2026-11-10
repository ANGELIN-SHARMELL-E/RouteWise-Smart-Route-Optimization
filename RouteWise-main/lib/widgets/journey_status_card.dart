import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/route_provider.dart';
import '../utils/constants.dart';

class JourneyStatusCard extends StatelessWidget {
  const JourneyStatusCard({super.key});

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000.0).toStringAsFixed(2)} km';
    }
    return '${meters.toStringAsFixed(0)} meters';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<RouteProvider>(
      builder: (context, provider, child) {
        if (!provider.journeyState.isJourneyActive) {
          return const SizedBox.shrink();
        }

        final currentDest = provider.journeyState.currentDestination;
        if (currentDest == null) return const SizedBox.shrink();

        final speed = provider.liveSpeed;
        final accuracy = provider.gpsAccuracy;
        final dist = provider.distanceToDestination;
        final eta = provider.estimatedArrivalTime;
        final radius = provider.journeySettings.arrivalRadius;

        return Card(
          elevation: 6,
          margin: const EdgeInsets.all(AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          color: isDark ? AppColors.surfaceDark.withOpacity(0.9) : Colors.white.withOpacity(0.95),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.navigation, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CURRENT DESTINATION',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          Text(
                            currentDest.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DISTANCE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            _formatDistance(dist),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ETA', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(eta),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${speed.toStringAsFixed(1)} km/h',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.gps_fixed, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '±${accuracy.toStringAsFixed(0)}m',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.radar, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${radius.toInt()}m radius',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
