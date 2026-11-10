import 'dart:async';
import 'package:flutter/material.dart';
import '../models/journey_state.dart';
import '../utils/constants.dart';

class JourneyProgressCard extends StatefulWidget {
  final JourneyState journeyState;
  final VoidCallback onCancel;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const JourneyProgressCard({
    required this.journeyState,
    required this.onCancel,
    required this.isExpanded,
    required this.onToggleExpand,
    super.key,
  });

  @override
  State<JourneyProgressCard> createState() => _JourneyProgressCardState();
}

class _JourneyProgressCardState extends State<JourneyProgressCard> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
  }

  @override
  void didUpdateWidget(covariant JourneyProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateElapsed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateElapsed() {
    final startTime = widget.journeyState.journeyStartTime;
    if (startTime != null) {
      setState(() {
        _elapsed = DateTime.now().difference(startTime);
      });
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    final secondsStr = seconds.toString().padLeft(2, '0');
    final minutesStr = minutes.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:${minutesStr}:${secondsStr}';
    }
    return '$minutesStr:$secondsStr';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final state = widget.journeyState;
    final totalStops = state.completedStops.length + state.remainingStops.length;
    final progress = totalStops > 0 ? state.completedStops.length / totalStops : 0.0;
    final progressPercentage = (progress * 100).round();

    if (!widget.isExpanded) {
      return Card(
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.navigation_outlined, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Journey: ${state.completedStops.length} / $totalStops completed',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$progressPercentage%',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onToggleExpand,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.surfaceDark, const Color(0xFF1E293B)]
                : [Colors.white, const Color(0xFFF8FAFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.navigation_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Journey Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 14),
                      label: const Text('End', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: widget.onCancel,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Collapse',
                      onPressed: widget.onToggleExpand,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),

            // Progress Bar & Percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stops: ${state.completedStops.length} / $totalStops completed',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  '$progressPercentage%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? const Color(0xFF2E3B4E) : const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),

            // Info Grid: Current Destination & Travel Stats
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CURRENT DESTINATION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.currentDestination?.name ?? 'Home Base',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: state.currentDestination?.id == 'unset_home' || state.remainingStops.isEmpty
                              ? AppColors.homeMarker
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ELAPSED TIME',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(_elapsed),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Distance Traveled vs Remaining
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.done_all, size: 14, color: AppColors.visited),
                    const SizedBox(width: 4),
                    Text(
                      'Traveled: ${state.totalDistance.toStringAsFixed(1)} km',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.hourglass_empty, size: 14, color: AppColors.pending),
                    const SizedBox(width: 4),
                    Text(
                      'Remaining: ${state.estimatedRemainingDistance.toStringAsFixed(1)} km',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
