import 'package:flutter/material.dart';
import '../models/location.dart';
import '../utils/constants.dart';

class LocationCard extends StatelessWidget {
  final Location location;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onToggleVisited;
  final Key cardKey;
  final bool isActive;

  const LocationCard({
    required this.location,
    required this.index,
    required this.onDelete,
    required this.onToggleVisited,
    required this.cardKey,
    this.isActive = false,
  }) : super(key: cardKey);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool isVisited = location.visited;
    final Color markerColor = isVisited
        ? AppColors.visited
        : (isActive ? AppColors.accent : AppColors.primary);
    final IconData markerIcon = isVisited
        ? Icons.check_circle_outlined
        : (isActive ? Icons.navigation : Icons.location_on_outlined);

    return Card(
      key: cardKey,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(
          color: isActive
              ? AppColors.primary
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: isActive ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onToggleVisited,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Icon(
                  Icons.drag_indicator,
                  color: Colors.grey,
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: markerColor.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  markerIcon,
                  color: markerColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${index + 1}. ${location.name}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: isVisited ? TextDecoration.lineThrough : null,
                              color: isVisited
                                  ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lat: ${location.latitude.toStringAsFixed(4)} · Lon: ${location.longitude.toStringAsFixed(4)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isVisited ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isVisited ? AppColors.visited : Colors.grey,
                ),
                tooltip: isVisited ? 'Mark as pending' : 'Mark as visited',
                onPressed: onToggleVisited,
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                tooltip: 'Remove stop',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
