import 'dart:async';
import 'dart:html' as html;

import 'local_storage_service_stub.dart';

class LocalStorageServiceImpl implements LocalStorageService {
  @override
  Future<String?> getString(String key) async {
    return html.window.localStorage[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    html.window.localStorage[key] = value;
  }
}
