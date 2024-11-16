import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class AvatarManager {
  AvatarManager._privateConstructor();
  static final AvatarManager _instance = AvatarManager._privateConstructor();
  factory AvatarManager() => _instance;

  final Map<String, String> _accountToAvatar = {};
  final List<String> _avatars = [];

  bool _initialized = false;

  Future<void> initialize(String assetFolderPath) async {
    if (!_initialized) {
      try {
        final manifestContent =
            await rootBundle.loadString('AssetManifest.json');
        final Map<String, dynamic> manifestMap =
            Map<String, dynamic>.from(json.decode(manifestContent));

        _avatars.addAll(
          manifestMap.keys
              .where((String key) => key.startsWith(assetFolderPath))
              .toList(),
        );

        if (_avatars.isEmpty) {
          throw Exception("No avatars found in $assetFolderPath.");
        }
        _initialized = true;
      } catch (e) {
        throw Exception("Failed to load avatars: $e");
      }
    }
  }

  String getAvatar(String accountId) {
    if (!_accountToAvatar.containsKey(accountId)) {
      final randomAvatar = _avatars[Random().nextInt(_avatars.length)];
      _accountToAvatar[accountId] = randomAvatar;
    }
    return _accountToAvatar[accountId]!;
  }
}
