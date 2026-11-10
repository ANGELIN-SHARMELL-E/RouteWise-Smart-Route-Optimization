import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/journey_settings.dart';
import '../services/route_provider.dart';
import '../utils/constants.dart';

class JourneySettingsSheet extends StatefulWidget {
  const JourneySettingsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const JourneySettingsSheet(),
    );
  }

  @override
  State<JourneySettingsSheet> createState() => _JourneySettingsSheetState();
}

class _JourneySettingsSheetState extends State<JourneySettingsSheet> {
  late double _arrivalRadius;
  late String _locationAccuracy;
  late bool _voiceGuidance;
  late bool _autoCenterMap;
  late bool _keepScreenAwake;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<RouteProvider>(context, listen: false);
    final settings = provider.journeySettings;
    _arrivalRadius = settings.arrivalRadius;
    _locationAccuracy = settings.locationAccuracy;
    _voiceGuidance = settings.voiceGuidance;
    _autoCenterMap = settings.autoCenterMap;
    _keepScreenAwake = settings.keepScreenAwake;
  }

  void _save(BuildContext context) {
    final provider = Provider.of<RouteProvider>(context, listen: false);
    provider.updateJourneySettings(
      JourneySettings(
        arrivalRadius: _arrivalRadius,
        locationAccuracy: _locationAccuracy,
        voiceGuidance: _voiceGuidance,
        autoCenterMap: _autoCenterMap,
        keepScreenAwake: _keepScreenAwake,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Journey Settings',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Arrival Radius Selector
          Text(
            'Arrival Radius: ${_arrivalRadius.round()} meters',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Slider(
            value: _arrivalRadius,
            min: 10,
            max: 200,
            divisions: 19,
            activeColor: AppColors.primary,
            label: '${_arrivalRadius.round()}m',
            onChanged: (val) {
              setState(() => _arrivalRadius = val);
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Location Accuracy Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Location Accuracy',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              DropdownButton<String>(
                value: _locationAccuracy,
                dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low (Fast/Cell)')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium (WiFi)')),
                  DropdownMenuItem(value: 'high', child: Text('High (GPS)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _locationAccuracy = val);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Voice Guidance Switch
          SwitchListTile(
            title: const Text('Voice Guidance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Speak arrival notification prompts', style: TextStyle(fontSize: 11)),
            value: _voiceGuidance,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _voiceGuidance = val),
            contentPadding: EdgeInsets.zero,
          ),

          // Auto Center Switch
          SwitchListTile(
            title: const Text('Auto Center Map', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Keep map centered on live position', style: TextStyle(fontSize: 11)),
            value: _autoCenterMap,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _autoCenterMap = val),
            contentPadding: EdgeInsets.zero,
          ),

          // Keep Screen Awake Switch
          SwitchListTile(
            title: const Text('Keep Screen Awake', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Prevent display timeout during active travel', style: TextStyle(fontSize: 11)),
            value: _keepScreenAwake,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _keepScreenAwake = val),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.lg),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
            ),
            onPressed: () => _save(context),
            child: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
