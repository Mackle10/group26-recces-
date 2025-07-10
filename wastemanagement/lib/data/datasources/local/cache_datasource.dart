abstract class CacheDataSource {
  Future<void> saveUserData(Map<String, dynamic> userData);
  Future<Map<String, dynamic>?> getUserData();
  Future<void> clearUserData();
  Future<void> saveAuthToken(String token);
  Future<String?> getAuthToken();
  Future<void> clearAuthToken();
}

class CacheDataSourceImpl implements CacheDataSource {
  // Implementation using SharedPreferences or Hive
  @override
  Future<void> clearAuthToken() async {
    // Implementation
  }

  @override
  Future<void> clearUserData() async {
    // Implementation
  }

  @override
  Future<String?> getAuthToken() async {
    // Implementation
    return null;
  }

  @override
  Future<Map<String, dynamic>?> getUserData() async {
    // Implementation
    return null;
  }

  @override
  Future<void> saveAuthToken(String token) async {
    // Implementation
  }

  @override
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    // Implementation
  }
}