import 'dart:io';

void main(List<String> args) {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('❌ pubspec.yaml not found!');
    exit(1);
  }

  final content = pubspecFile.readAsStringSync();
  final versionRegex =
      RegExp(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)$', multiLine: true);
  final match = versionRegex.firstMatch(content);

  if (match == null) {
    print('❌ Could not parse version from pubspec.yaml');
    exit(1);
  }

  final major = int.parse(match.group(1)!);
  final minor = int.parse(match.group(2)!);
  final patch = int.parse(match.group(3)!);
  final build = int.parse(match.group(4)!);

  // Increment build number
  final newBuild = build + 1;
  final newVersion = '$major.$minor.$patch+$newBuild';

  // Replace version line
  final newContent = content.replaceFirst(
    versionRegex,
    'version: $newVersion',
  );

  pubspecFile.writeAsStringSync(newContent);

  print('✅ Version updated: $major.$minor.$patch+$build → $newVersion');
  print('📦 Build number incremented: $build → $newBuild');
}

