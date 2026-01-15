import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:writr/services/scrivener_service.dart';
import 'package:writr/utils/rtf_parser.dart';

void main() {
  test('ScrivenerService loads BinderItem UUID and content', () async {
    final tempDir = await Directory.systemTemp.createTemp('writr_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    const itemUuid = '0A7EDD9F-9DE0-4CC9-9AC1-EE0E3769B6A8';
    final projectDir = Directory(path.join(tempDir.path, 'Example.scriv'));
    await projectDir.create(recursive: true);

    final scrivxFile = File(path.join(projectDir.path, 'Example.scrivx'));
    await scrivxFile.writeAsString(
      '''
<?xml version="1.0" encoding="UTF-8"?>
<ScrivenerProject Version="2.0">
  <Binder>
    <BinderItem UUID="$itemUuid" Type="Text">
      <Title>Scene</Title>
    </BinderItem>
  </Binder>
</ScrivenerProject>
''',
    );

    final dataDir = Directory(path.join(projectDir.path, 'Files', 'Data', itemUuid));
    await dataDir.create(recursive: true);
    final contentFile = File(path.join(dataDir.path, 'content.rtf'));
    await contentFile.writeAsString(plainTextToRtf('Hello world'));

    final service = ScrivenerService();
    await service.loadProject(projectDir.path);

    expect(service.currentProject, isNotNull);
    expect(service.currentProject!.binderItems, isNotEmpty);
    expect(service.currentProject!.binderItems.first.id, itemUuid);
    expect(service.currentProject!.textContents[itemUuid], 'Hello world');
  });
}

