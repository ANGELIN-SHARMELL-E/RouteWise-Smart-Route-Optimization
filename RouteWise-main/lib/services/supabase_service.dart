import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/location.dart';

class SupabaseService {
  static const String _url = 'https://bocjpxfufhjpofbgpzfb.supabase.co';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJvY2pweGZ1ZmhqcG9mYmdwemZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE0MzEzMDMsImV4cCI6MjA5NzAwNzMwM30.PXUlwh1DCyss6F6zxR2TvUB3x-JC8giUBkUPQ9WqU7c';

  static Future<void> initialize() async {
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static String? get currentUserId => currentUser?.id;
  static bool get isLoggedIn => currentUser != null;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<AuthResponse> signUp(String email, String password) =>
      client.auth.signUp(email: email, password: password);

  static Future<AuthResponse> signIn(String email, String password) =>
      client.auth.signInWithPassword(email: email, password: password);

  static Future<void> signOut() => client.auth.signOut();

  // ── Routes ────────────────────────────────────────────────────────────────

  static Future<String?> saveRoute({
    required String name,
    required Location home,
    required List<Location> stops,
    required bool optimized,
  }) async {
    if (currentUserId == null) return null;
    try {
      final routeRes = await client.from('routes').insert({
        'user_id': currentUserId,
        'name': name,
        'home_name': home.name,
        'home_lat': home.latitude,
        'home_lng': home.longitude,
        'optimized': optimized,
      }).select('id').single();

      final routeId = routeRes['id'] as String;

      if (stops.isNotEmpty) {
        await client.from('stops').insert(
          stops.asMap().entries.map((e) => {
            'route_id': routeId,
            'name': e.value.name,
            'latitude': e.value.latitude,
            'longitude': e.value.longitude,
            'stop_order': e.key,
            'visited': e.value.visited,
          }).toList(),
        );
      }
      return routeId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseService] saveRoute error: $e');
      }
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> loadRoutes() async {
    if (currentUserId == null) return [];
    try {
      final routes = await client
          .from('routes')
          .select('*, stops(*)')
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(routes);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseService] loadRoutes error: $e');
      }
      return [];
    }
  }

  static Future<bool> deleteRoute(String routeId) async {
    try {
      await client.from('routes').delete().eq('id', routeId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseService] deleteRoute error: $e');
      }
      return false;
    }
  }
}
