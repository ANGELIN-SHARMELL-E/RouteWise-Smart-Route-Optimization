import 'dart:async';

import 'package:flutter/material.dart';
import '../models/location.dart';
import '../models/place_suggestion.dart';
import '../services/location_search_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';

class AddLocationDialog extends StatefulWidget {
  final bool isSettingHome;

  const AddLocationDialog({this.isSettingHome = false, super.key});

  @override
  State<AddLocationDialog> createState() => _AddLocationDialogState();
}

class _AddLocationDialogState extends State<AddLocationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final LocationSearchService _searchService = LocationSearchService();
  final List<PlaceSuggestion> _suggestions = [];

  bool _isLoading = false;
  bool _isSearching = false;
  String? _searchError;
  Timer? _debounce;
  PlaceSuggestion? _selectedSuggestion;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions.clear();
        _searchError = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final results = await _searchService.fetchSuggestions(query);
      if (mounted) {
        setState(() {
          _suggestions
            ..clear()
            ..addAll(results);
          if (results.isEmpty) {
            _searchError = null; // show "no suggestions found" message instead
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = 'Unable to load suggestions.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    _selectedSuggestion = null;
    _nameController.clear();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetchSuggestions(_searchController.text);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedSuggestion == null) {
        throw Exception('Please select a place from the suggestions.');
      }

      final details = await _searchService.getPlaceDetails(_selectedSuggestion!.placeId);
      if (details == null) {
        throw Exception('Unable to resolve selected place.');
      }

      final location = details.copyWith(
        id: details.placeId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      );

      if (mounted) {
        Navigator.of(context).pop(location);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is String ? e : 'Please fix the highlighted fields.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHome = widget.isSettingHome;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isHome ? Icons.home_outlined : Icons.add_location_alt_outlined,
                      color: isHome ? AppColors.homeMarker : AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        isHome ? 'Edit Home Location' : 'Add Stop Location',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Search Location',
                          hintText: 'Search for a place',
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (_) => _onSearchChanged(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a place name.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (_isSearching)
                  const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_searchError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      _searchError!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  )
                else if (_suggestions.isEmpty && _searchController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      'No suggestions found. Try a different search.',
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75)),
                    ),
                  )
                else if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: AppSpacing.sm),
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: Material(
                      type: MaterialType.canvas,
                      color: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: theme.brightness == Brightness.dark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        final selected = suggestion == _selectedSuggestion;
                        return ListTile(
                          title: Text(suggestion.description),
                          selected: selected,
                          trailing: selected ? const Icon(Icons.check, color: AppColors.secondary) : null,
                          onTap: () {
                            setState(() {
                              _selectedSuggestion = suggestion;
                              _nameController.text = suggestion.description;
                              _searchController.text = suggestion.description;
                              _suggestions.clear();
                            });
                          },
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(height: 1),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isHome ? 'Save Home' : 'Add Stop'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
