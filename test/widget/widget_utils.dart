import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/settings/backup_file_gateway.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_utils.dart';

class FakeBackupGateway implements BackupFileGateway {
  String? savedJson;
  String? pickedJson;

  @override
  Future<String?> saveBackup(String json) async {
    savedJson = json;
    return '/fake/gtd_backup.json';
  }

  @override
  Future<String?> pickBackupJson() async => pickedJson;
}

/// Widget 测试环境：内存库 + mock prefs + Fake 备份网关。
/// 注意：不 import app.dart（SettleApp 到 Task 33 才创建）；
/// 整应用测试在 app_smoke_test.dart 内自行用 [overrides] 组装 ProviderScope。
class TestEnv {
  TestEnv._(this.db, this.prefs);

  final AppDatabase db;
  final SharedPreferences prefs;
  final FakeBackupGateway backup = FakeBackupGateway();

  static Future<TestEnv> create() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return TestEnv._(createTestDatabase(), prefs);
  }

  List<Override> get overrides => [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        backupFileGatewayProvider.overrideWithValue(backup),
      ];

  /// 包单个页面（自带本地化 delegates）。
  Widget wrap(Widget home, {List<Override> extraOverrides = const []}) {
    return ProviderScope(
      overrides: [...overrides, ...extraOverrides],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
  }

  Future<Map<String, dynamic>> decodeSavedJson() async =>
      jsonDecode(backup.savedJson!) as Map<String, dynamic>;
}
