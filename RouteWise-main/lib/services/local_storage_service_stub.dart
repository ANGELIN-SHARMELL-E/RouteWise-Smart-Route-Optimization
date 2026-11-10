import 'dart:async';

abstract class LocalStorageService {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
}

class LocalStorageServiceImpl implements LocalStorageService {
  @override
  Future<String?> getString(String key) async {
    return null;
  }

  @override
  Future<void> setString(String key, String value) async {}
}
