import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:fast_flutter_driver_tool/src/preparing_tests/file_system.dart';
import 'package:meta/meta.dart';

Future<void> overrideResolution(
  String resolution,
  Future<void> Function() test, {
  @required Logger logger,
}) async {
  final native = nativeResolutionFile;
  final nativeCopy = '$native\_copy'; // ignore: unnecessary_string_escapes
  final resolutionFile = File(native);
  if (resolutionFile.existsSync()) {
    await resolutionFile.copy(nativeCopy);
  }

  final dimensions = resolution.split('x');
  await _updateResolution(
    resolutionFile: resolutionFile,
    width: int.parse(dimensions[0]),
    height: int.parse(dimensions[1]),
  );

  try {
    await test();
  } finally {
    if (exists(nativeCopy)) {
      await File(native).delete();
      await File(nativeCopy).rename(native);
    } else {
      logger.stderr(
        'Was not able to restore native as the copy does not exist',
      );
      exitCode = 1;
    }
  }
}

Future<void> _updateResolution({
  @required int width,
  @required int height,
  @required File resolutionFile,
}) async {
  final read = await resolutionFile.readAsString();
  final updatedNativeFile = _replaceResolution(
    read,
    width: width,
    height: height,
  );
  await resolutionFile.writeAsString(updatedNativeFile);
}

String _replaceResolution(
  String nativeContent, {
  @required int width,
  @required int height,
}) {
  return nativeContent
      .replaceWidth(width)
      .replaceHeight(height)
      .replaceLegacyWidth(width)
      .replaceLegacyHeight(height);
}

extension on String {
  String replaceWidth(int width) {
    return replaceAllMapped(
      RegExp(r'kFlutterWindowWidth = (\d+);'),
      (m) => 'kFlutterWindowWidth = $width;',
    );
  }

  String replaceHeight(int height) {
    return replaceAllMapped(
      RegExp(r'kFlutterWindowHeight = (\d+);'),
      (m) => 'kFlutterWindowHeight = $height;',
    );
  }

  String replaceLegacyWidth(int width) {
    return replaceAllMapped(
      RegExp(r'window_properties.width = (\d+);'),
      (m) => 'window_properties.width = $width;',
    );
  }

  String replaceLegacyHeight(int height) {
    return replaceAllMapped(
      RegExp(r'window_properties.height = (\d+);'),
      (m) => 'window_properties.height = $height;',
    );
  }
}
