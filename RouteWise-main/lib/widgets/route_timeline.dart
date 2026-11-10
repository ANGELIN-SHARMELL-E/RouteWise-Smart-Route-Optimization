import 'package:flutter/material.dart';
import '../models/location.dart';
import '../services/route_optimizer.dart';
import '../utils/constants.dart';

class RouteTimeline extends StatelessWidget {
  final Location home;
  final List<Location> optimizedRoute;
  final String? activeStopId;

  const RouteTimeline({
    required this.home,
    required this.optimizedRoute,
    this.activeStopId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (optimizedRoute.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.alt_route,
                size: 64,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondaryDark.withOpacity(0.3)
                    : AppColors.textSecondaryLight.withOpacity(0.3),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No destinations added yet.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add destinations and optimize the path to see your timeline.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Build the list of nodes: Home -> Stop 1 -> ... -> Stop N -> Home
    final List<Location> fullTimeline = [home, ...optimizedRoute, home];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fullTimeline.length,
      itemBuilder: (context, index) {
        final node = fullTimeline[index];
        final isStart = index == 0;
        final isEnd = index == fullTimeline.length - 1;
        final isHomeNode = isStart || isEnd;

        // Calculate distance from previous stop (for all except start node)
        double distanceToPrevious = 0.0;
        if (index > 0) {
          final previousNode = fullTimeline[index - 1];
          distanceToPrevious = RouteOptimizer.calculateDistance(
            previousNode.latitude,
            previousNode.longitude,
            node.latitude,
            node.longitude,
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: Timeline Line & Indicator Icon
              SizedBox(
                width: 60,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Vertical Line
                    if (!isEnd)
                      Positioned(
                        top: 24,
                        bottom: 0,
                        width: 2,
                        child: Container(
                          color: isHomeNode
                              ? AppColors.homeMarker.withOpacity(0.3)
                              : AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                    
                    // Circular Node Badge
                    Positioned(
                      top: 4,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isHomeNode
                              ? AppColors.homeMarker
                              : (node.visited
                                  ? AppColors.visited
                                  : (node.id == activeStopId ? AppColors.accent : AppColors.primary)),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isStart
                                ? Icons.play_arrow_rounded
                                : isEnd
                                    ? Icons.flag_rounded
                                    : node.visited
                                        ? Icons.check
                                        : (node.id == activeStopId ? Icons.navigation : null),
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    
                    // Route index overlay for normal stops
                    if (!isHomeNode && !node.visited && node.id != activeStopId)
                      Positioned(
                        top: 4,
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: Center(
                            child: Text(
                              index.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Right: Content Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.lg,
                    right: AppSpacing.md,
                    left: AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Distance spacer badge (if any)
                      if (index > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Travel distance: ${distanceToPrevious.toStringAsFixed(2)} km',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.cyanAccent
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ),

                      // Destination Name
                      Text(
                        isStart
                            ? 'Start: ${node.name}'
                            : isEnd
                                ? 'Return: ${node.name}'
                                : node.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isHomeNode ? FontWeight.bold : FontWeight.w600,
                          color: isHomeNode
                              ? AppColors.homeMarker
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      
                      // Coordinates/Visited description
                      if (!isEnd) ...[
                        const SizedBox(height: 2),
                        Text(
                          isStart
                              ? 'Starting home base location'
                              : node.visited
                                  ? 'Visited stop'
                                  : (node.id == activeStopId ? 'Active Destination 🧭' : 'Pending visit'),
                          style: TextStyle(
                            fontSize: 12,
                            color: node.visited
                                ? AppColors.visited
                                : (node.id == activeStopId ? AppColors.accent : Colors.grey[500]),
                            fontStyle: FontStyle.italic,
                            fontWeight: node.id == activeStopId ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
