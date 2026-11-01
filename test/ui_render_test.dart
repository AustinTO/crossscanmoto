import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/main.dart';

void main() {
  testWidgets('renders dashboard screenshots at phone and desktop widths',
      (tester) async {
    await tester.runAsync(_loadScreenshotFonts);
    final directory = Directory('artifacts/ui');
    await tester.runAsync(() => directory.create(recursive: true));
    for (final size in [
      const Size(360, 800),
      const Size(390, 844),
      const Size(900, 900),
    ]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const RepaintBoundary(
        key: ValueKey('dashboard-shot'),
        child: MotoDiagApp(),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('dashboard-shot')),
      );
      final image =
          await tester.runAsync(() => boundary.toImage(pixelRatio: 2));
      final png = await tester
          .runAsync(() => image!.toByteData(format: ui.ImageByteFormat.png));
      final width = size.width.toInt();
      await tester.runAsync(() => File('${directory.path}/dashboard-$width.png')
          .writeAsBytes(png!.buffer.asUint8List()));
      image!.dispose();
    }

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const RepaintBoundary(
      key: ValueKey('dashboard-shot'),
      child: MotoDiagApp(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adapter').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final adapterBoundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('dashboard-shot')),
    );
    final adapterImage =
        await tester.runAsync(() => adapterBoundary.toImage(pixelRatio: 2));
    final adapterPng = await tester.runAsync(
        () => adapterImage!.toByteData(format: ui.ImageByteFormat.png));
    await tester.runAsync(() => File('${directory.path}/adapter-390.png')
        .writeAsBytes(adapterPng!.buffer.asUint8List()));
    adapterImage!.dispose();
    await tester.binding.setSurfaceSize(null);
  });
}

Future<void> _loadScreenshotFonts() async {
  final flutterRoot = await _resolveFlutterRoot();
  final fontRoot = '$flutterRoot/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final fileName in [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf'
  ]) {
    final bytes = await File('$fontRoot/$fileName').readAsBytes();
    roboto.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await roboto.load();
  final icons = await File('$fontRoot/MaterialIcons-Regular.otf').readAsBytes();
  await (FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(icons))))
      .load();
}

Future<String> _resolveFlutterRoot() async {
  final configuredRoot = Platform.environment['FLUTTER_ROOT'];
  if (configuredRoot != null && configuredRoot.isNotEmpty)
    return configuredRoot;
  final config =
      jsonDecode(await File('.dart_tool/package_config.json').readAsString())
          as Map<String, dynamic>;
  final packages = config['packages'] as List<dynamic>;
  final flutter = packages
      .cast<Map<String, dynamic>>()
      .firstWhere((entry) => entry['name'] == 'flutter');
  final packageRoot = Uri.parse(flutter['rootUri'] as String).toFilePath();
  return Directory(packageRoot).parent.parent.path;
}
