import 'dart:io';

// Exercise the macOS plugin's Dart implementation before the native channel.
// ignore: implementation_imports
import 'package:file_picker/src/file_picker_macos.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/features/settings/backup_file_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('macOS save picker opens and the gateway writes UTF-8 JSON', () async {
    final directory = await Directory.systemTemp.createTemp('settle-backup-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/backup.json');
    FilePickerMacOS.registerWith();

    const channel = MethodChannel('miguelruivo.flutter.plugins.filepicker');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.arguments['allowedExtensions'], ['json']);
      return switch (call.method) {
        'saveFile' => file.path,
        'pickFiles' => [file.path],
        _ => throw StateError('Unexpected picker call: ${call.method}'),
      };
    });

    const json = '{"app":"settle","text":"备份"}';
    final gateway = FilePickerBackupGateway();
    expect(await gateway.saveBackup(json), file.path);
    expect(await file.readAsString(), json);
    expect(await gateway.pickBackupJson(), json);
  });
}
