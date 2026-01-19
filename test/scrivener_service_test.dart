import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:writr/models/scrivener_project.dart';
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

  test('ScrivenerService preserves Scrivener RTF and .scrivx when saving unchanged', () async {
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
    await contentFile.writeAsString(
      r"{\rtf1\ansi\deff0{\fonttbl{\f0 Times New Roman;}}\uc1\pard\f0\fs24 Hello \b world\b0\par}",
    );

    final scrivxBefore = await scrivxFile.readAsString();
    final rtfBefore = await contentFile.readAsString();

    final service = ScrivenerService();
    await service.loadProject(projectDir.path);
    await service.saveProject();

    final scrivxAfter = await scrivxFile.readAsString();
    final rtfAfter = await contentFile.readAsString();

    expect(scrivxAfter, scrivxBefore);
    expect(rtfAfter, rtfBefore);
  });

  test('ScrivenerService updates RTF text without removing formatting control words', () async {
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
    await contentFile.writeAsString(
      r"{\rtf1\ansi\deff0{\fonttbl{\f0 Times New Roman;}}\uc1\pard\f0\fs24 Hello \b world\b0\par}",
    );

    final service = ScrivenerService();
    await service.loadProject(projectDir.path);

    // Replace "world" with "earth" while preserving the existing bold markers.
    service.updateTextContent(itemUuid, 'Hello earth\n');

    await service.saveProject();

    final rtfAfter = await contentFile.readAsString();
    expect(rtfAfter, contains(r'{\fonttbl'));
    expect(rtfAfter, contains(r'\b'));
    expect(rtfAfter, contains(r'\b0'));
    expect(rtfAfter, contains('earth'));
    expect(rtfAfter, isNot(contains('world')));
  });

  group('Scrivener Mode Protection', () {
    test('loaded Scrivener projects are in scrivener mode', () async {
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
      await scrivxFile.writeAsString('''
<?xml version="1.0" encoding="UTF-8"?>
<ScrivenerProject Version="2.0">
  <Binder>
    <BinderItem UUID="$itemUuid" Type="Text">
      <Title>Scene</Title>
    </BinderItem>
  </Binder>
</ScrivenerProject>
''');

      final dataDir = Directory(path.join(projectDir.path, 'Files', 'Data', itemUuid));
      await dataDir.create(recursive: true);
      final contentFile = File(path.join(dataDir.path, 'content.rtf'));
      await contentFile.writeAsString(plainTextToRtf('Hello world'));

      final service = ScrivenerService();
      await service.loadProject(projectDir.path);

      expect(service.projectMode, ProjectMode.scrivener);
      expect(service.isScrivenerMode, isTrue);
    });

    test('addBinderItem throws in Scrivener mode', () async {
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
      await scrivxFile.writeAsString('''
<?xml version="1.0" encoding="UTF-8"?>
<ScrivenerProject Version="2.0">
  <Binder>
    <BinderItem UUID="$itemUuid" Type="Text">
      <Title>Scene</Title>
    </BinderItem>
  </Binder>
</ScrivenerProject>
''');

      final dataDir = Directory(path.join(projectDir.path, 'Files', 'Data', itemUuid));
      await dataDir.create(recursive: true);
      final contentFile = File(path.join(dataDir.path, 'content.rtf'));
      await contentFile.writeAsString(plainTextToRtf('Hello world'));

      final service = ScrivenerService();
      await service.loadProject(projectDir.path);

      expect(
        () => service.addBinderItem(title: 'New Doc', type: BinderItemType.text),
        throwsA(isA<StateError>()),
      );
    });

    test('deleteBinderItem throws in Scrivener mode', () async {
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
      await scrivxFile.writeAsString('''
<?xml version="1.0" encoding="UTF-8"?>
<ScrivenerProject Version="2.0">
  <Binder>
    <BinderItem UUID="$itemUuid" Type="Text">
      <Title>Scene</Title>
    </BinderItem>
  </Binder>
</ScrivenerProject>
''');

      final dataDir = Directory(path.join(projectDir.path, 'Files', 'Data', itemUuid));
      await dataDir.create(recursive: true);
      final contentFile = File(path.join(dataDir.path, 'content.rtf'));
      await contentFile.writeAsString(plainTextToRtf('Hello world'));

      final service = ScrivenerService();
      await service.loadProject(projectDir.path);

      expect(
        () => service.deleteBinderItem(itemUuid),
        throwsA(isA<StateError>()),
      );
    });

    test('renameBinderItem throws in Scrivener mode', () async {
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
      await scrivxFile.writeAsString('''
<?xml version="1.0" encoding="UTF-8"?>
<ScrivenerProject Version="2.0">
  <Binder>
    <BinderItem UUID="$itemUuid" Type="Text">
      <Title>Scene</Title>
    </BinderItem>
  </Binder>
</ScrivenerProject>
''');

      final dataDir = Directory(path.join(projectDir.path, 'Files', 'Data', itemUuid));
      await dataDir.create(recursive: true);
      final contentFile = File(path.join(dataDir.path, 'content.rtf'));
      await contentFile.writeAsString(plainTextToRtf('Hello world'));

      final service = ScrivenerService();
      await service.loadProject(projectDir.path);

      expect(
        () => service.renameBinderItem(itemUuid, 'New Title'),
        throwsA(isA<StateError>()),
      );
    });

    test('updateTextContent is allowed in Scrivener mode', () async {
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
      await scrivxFile.writeAsString('''
<?xml version="1.0" encoding="UTF-8"?>
<ScrivenerProject Version="2.0">
  <Binder>
    <BinderItem UUID="$itemUuid" Type="Text">
      <Title>Scene</Title>
    </BinderItem>
  </Binder>
</ScrivenerProject>
''');

      final dataDir = Directory(path.join(projectDir.path, 'Files', 'Data', itemUuid));
      await dataDir.create(recursive: true);
      final contentFile = File(path.join(dataDir.path, 'content.rtf'));
      await contentFile.writeAsString(plainTextToRtf('Hello world'));

      final service = ScrivenerService();
      await service.loadProject(projectDir.path);

      // This should NOT throw - text editing is allowed
      service.updateTextContent(itemUuid, 'Updated text');
      expect(service.currentProject!.textContents[itemUuid], 'Updated text');
    });

    test('Scrivener mode save only writes modified RTF files', () async {
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
      await scrivxFile.writeAsString('''
<?xml version="1.0" encoding="UTF-8"?>
<ScrivenerProject Version="2.0">
  <Binder>
    <BinderItem UUID="$itemUuid" Type="Text">
      <Title>Scene</Title>
    </BinderItem>
  </Binder>
</ScrivenerProject>
''');

      final dataDir = Directory(path.join(projectDir.path, 'Files', 'Data', itemUuid));
      await dataDir.create(recursive: true);
      final contentFile = File(path.join(dataDir.path, 'content.rtf'));
      await contentFile.writeAsString(plainTextToRtf('Hello world'));

      final scrivxBefore = await scrivxFile.readAsString();

      final service = ScrivenerService();
      await service.loadProject(projectDir.path);

      // Edit content
      service.updateTextContent(itemUuid, 'Updated text');
      await service.saveProject();

      // .scrivx should NOT have changed
      final scrivxAfter = await scrivxFile.readAsString();
      expect(scrivxAfter, scrivxBefore);

      // RTF content should have updated text
      final rtfAfter = await contentFile.readAsString();
      expect(rtfToPlainText(rtfAfter), 'Updated text');
    });
  });
}
