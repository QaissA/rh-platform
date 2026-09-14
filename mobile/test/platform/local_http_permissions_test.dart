import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;

  setUpAll(() {
    root = _mobileRoot();
  });

  test('debug network_security_config allows 10.0.2.2 and localhost', () {
    final file = File(
      '${root.path}/android/app/src/debug/res/xml/network_security_config.xml',
    );
    expect(file.existsSync(), isTrue);
    final xml = file.readAsStringSync();
    expect(xml, contains('10.0.2.2'));
    expect(xml, contains('localhost'));
    expect(xml, contains('cleartextTrafficPermitted="true"'));
  });

  test('main AndroidManifest has INTERNET and no release cleartext', () {
    final xml = File('${root.path}/android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(xml, contains('android.permission.INTERNET'));
    expect(xml, isNot(contains('usesCleartextTraffic="true"')));
  });

  test('debug AndroidManifest enables cleartext via network config', () {
    final xml = File('${root.path}/android/app/src/debug/AndroidManifest.xml')
        .readAsStringSync();
    expect(xml, contains('android.permission.INTERNET'));
    expect(xml, contains('usesCleartextTraffic="true"'));
    expect(xml, contains('@xml/network_security_config'));
  });

  test('Info.plist allows local HTTP and chat file attachments', () {
    final plist =
        File('${root.path}/ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('NSAllowsLocalNetworking'));
    expect(plist, contains('NSPhotoLibraryUsageDescription'));
    expect(plist, isNot(contains('NSPhotoLibraryAddUsageDescription')));
  });

  test('main AndroidManifest skips unused media storage permissions', () {
    final xml = File('${root.path}/android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(xml, isNot(contains('READ_MEDIA_IMAGES')));
    expect(xml, isNot(contains('READ_EXTERNAL_STORAGE')));
  });
}

Directory _mobileRoot() {
  final current = Directory.current;
  if (_isMobileRoot(current)) return current;
  final nested = Directory('${current.path}/mobile');
  if (_isMobileRoot(nested)) return nested;
  fail('Could not find Flutter package root from ${current.path}');
}

bool _isMobileRoot(Directory dir) {
  return File('${dir.path}/pubspec.yaml').existsSync() &&
      File('${dir.path}/android/app/src/main/AndroidManifest.xml')
          .existsSync();
}
