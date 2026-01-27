import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  // Create screenshots directory
  final screenshotDir = Directory('test_output/screenshots');
  if (!screenshotDir.existsSync()) {
    screenshotDir.createSync(recursive: true);
  }

  await integrationDriver(
    onScreenshot: (String screenshotName, List<int> screenshotBytes, [Map<String, Object?>? args]) async {
      final File image = File('test_output/screenshots/$screenshotName.png');
      image.writeAsBytesSync(screenshotBytes);
      print('Screenshot saved: ${image.path}');
      return true;
    },
  );
}
