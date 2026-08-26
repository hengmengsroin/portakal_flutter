import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:portakal_flutter/portakal_flutter.dart';
import 'package:example/src/examples/example_case.dart';
import 'package:example/src/examples/example_catalog.dart';

void main() {
  group('Example Catalog & Registry Integrity Tests (20 Cases)', () {
    test('Catalog contains exactly 20 use cases across all domain categories', () {
      expect(ExampleCatalog.allCases.length, equals(20));
      expect(ExampleCategory.values.length, equals(9));

      for (final category in ExampleCategory.values) {
        final cases = ExampleCatalog.getByCategory(category);
        expect(
          cases,
          isNotEmpty,
          reason: 'Category ${category.name} should have at least one example case',
        );
      }
    });

    test('All example IDs are strictly unique', () {
      final ids = <String>{};
      for (final c in ExampleCatalog.allCases) {
        expect(c.id, isNotEmpty);
        expect(
          ids.contains(c.id),
          isFalse,
          reason: 'Duplicate example ID detected: "${c.id}"',
        );
        ids.add(c.id);
      }
    });

    test('All metadata fields are non-empty and well-formed', () {
      for (final c in ExampleCatalog.allCases) {
        expect(c.title.trim(), isNotEmpty, reason: '${c.id} title cannot be empty');
        expect(c.description.trim(), isNotEmpty, reason: '${c.id} description cannot be empty');
        expect(c.recommendedMedia.trim(), isNotEmpty, reason: '${c.id} recommendedMedia cannot be empty');
        expect(c.sourcePath.trim(), isNotEmpty, reason: '${c.id} sourcePath cannot be empty');
        expect(c.testedProtocols, isNotEmpty, reason: '${c.id} must declare testedProtocols');
      }
    });

    test('All source paths point to existing files on disk (CI-safe)', () {
      for (final c in ExampleCatalog.allCases) {
        // Handle running tests from either repo root or example/ directory
        final pathInCwd = c.sourcePath;
        final pathInExample = 'example/${c.sourcePath}';
        final exists = File(pathInCwd).existsSync() || File(pathInExample).existsSync();
        expect(
          exists,
          isTrue,
          reason: 'Source file "${c.sourcePath}" must exist on disk',
        );
      }
    });

    test('Every example builds, resolves, and generates valid PreviewScene with positive dimensions', () {
      for (final c in ExampleCatalog.allCases) {
        final builder = c.buildLabel();
        final job = builder.resolve();

        expect(job.widthDots, greaterThan(0), reason: '${c.id} widthDots must be > 0');
        expect(job.heightDots, greaterThan(0), reason: '${c.id} heightDots must be > 0');

        final scene = PreviewScene.fromResolved(job);
        expect(scene.widthDots, equals(job.widthDots));
        expect(scene.heightDots, equals(job.heightDots));
        expect(scene.items, isNotEmpty, reason: '${c.id} scene items cannot be empty');
      }
    });

    test('Every tested protocol compiles cleanly without exceptions under throwError policy', () {
      for (final c in ExampleCatalog.allCases) {
        final job = c.buildLabel().resolve();
        for (final protocol in c.testedProtocols) {
          final bytes = compileExample(
            protocol,
            job,
            policy: UnsupportedFeaturePolicy.throwError,
          );
          expect(
            bytes,
            isNotEmpty,
            reason: '${c.id} compiled with ${protocol.displayName} must produce bytes',
          );

          // Verify deterministic output
          final bytes2 = compileExample(
            protocol,
            job,
            policy: UnsupportedFeaturePolicy.throwError,
          );
          expect(
            bytes,
            equals(bytes2),
            reason: '${c.id} compilation with ${protocol.displayName} must be deterministic',
          );
        }
      }
    });

    test('Filtering and ID lookups function correctly in ExampleCatalog', () {
      expect(ExampleCatalog.getById('retail_price_label'), isNotNull);
      expect(ExampleCatalog.getById('non_existent_id'), isNull);

      final retailCases = ExampleCatalog.filterCases(category: ExampleCategory.retail);
      expect(retailCases.length, equals(2));

      final searchResults = ExampleCatalog.filterCases(searchQuery: 'amoxicillin');
      expect(searchResults.length, greaterThanOrEqualTo(1));
    });
  });
}
