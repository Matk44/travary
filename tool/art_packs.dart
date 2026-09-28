// Builds, validates and publishes Travary art packs. The app never uploads
// or edits packs; this tool (run by an operator) does.
//
//   dart run tool/art_packs.dart build <source-dir> [--catalog art_packs/catalog.json]
//       [--out build/art_packs] [--dry-run]
//   dart run tool/art_packs.dart publish [--catalog art_packs/catalog.json]
//       [--out build/art_packs] --emulator 127.0.0.1:9199 --bucket <bucket> [--dry-run]
//   dart run tool/art_packs.dart publish --bucket travary-444.firebasestorage.app
//       --production [--dry-run]
//
// Production uploads use the operator's own Google credentials: the token
// from $ART_PACKS_ACCESS_TOKEN, else `gcloud auth print-access-token`.
// Nothing is ever stored in the repository. See docs/ART_PACKS.md.
import 'dart:io';

import 'src/bucket.dart';
import 'src/pack_builder.dart';
import 'src/publisher.dart';

Future<void> main(List<String> args) async {
  try {
    final command = args.isEmpty ? '' : args.first;
    final options = _Options(args.skip(1).toList());
    final catalog = File(options.value('--catalog') ?? 'art_packs/catalog.json');
    final out = Directory(options.value('--out') ?? 'build/art_packs');
    final dryRun = options.flag('--dry-run');
    switch (command) {
      case 'build':
        final source = options.positional.singleOrNull;
        if (source == null) throw const PublishException('Which pack? build <source-dir>');
        options.done(maxPositional: 1);
        await buildAndRecord(
          source: Directory(source),
          catalogFile: catalog,
          outDir: out,
          dryRun: dryRun,
          now: DateTime.now(),
        );
      case 'publish':
        final emulator = options.value('--emulator');
        final bucketName = options.value('--bucket');
        final production = options.flag('--production');
        options.done(maxPositional: 0);
        if (bucketName == null) throw const PublishException('--bucket is required.');
        if (emulator != null && production) throw const PublishException('Choose --emulator or --production.');
        if (emulator == null && !production) {
          throw const PublishException('Add --emulator <host:port> or --production.');
        }
        ArtPackBucket? bucket;
        if (!dryRun) {
          bucket = emulator != null
              ? EmulatorBucket(host: emulator, bucket: bucketName)
              : CloudStorageBucket(bucket: bucketName, accessToken: await _accessToken());
        }
        await publishArtPacks(catalogFile: catalog, outDir: out, bucket: bucket, dryRun: dryRun);
      default:
        throw const PublishException(
          'Usage: dart run tool/art_packs.dart build|publish ... (see the top of this file)',
        );
    }
  } on PublishException catch (e) {
    stderr.writeln('Refused: ${e.message}');
    exitCode = 1;
  }
}

Future<String> _accessToken() async {
  final fromEnvironment = Platform.environment['ART_PACKS_ACCESS_TOKEN'];
  if (fromEnvironment != null && fromEnvironment.isNotEmpty) return fromEnvironment;
  try {
    final result = await Process.run('gcloud', ['auth', 'print-access-token']);
    final token = '${result.stdout}'.trim();
    if (result.exitCode == 0 && token.isNotEmpty) return token;
  } on ProcessException {
    // Fall through to the message below.
  }
  throw const PublishException('No Google credentials. Run `gcloud auth login` or set ART_PACKS_ACCESS_TOKEN.');
}

class _Options {
  _Options(List<String> args) {
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (_flags.contains(arg)) {
        _given.add(arg);
      } else if (_valued.contains(arg)) {
        if (i + 1 >= args.length) throw PublishException('$arg needs a value.');
        _values[arg] = args[++i];
      } else if (arg.startsWith('--')) {
        throw PublishException('Unknown option $arg.');
      } else {
        positional.add(arg);
      }
    }
  }

  static const _flags = {'--dry-run', '--production'};
  static const _valued = {'--catalog', '--out', '--emulator', '--bucket'};
  final _given = <String>{};
  final _values = <String, String>{};
  final positional = <String>[];

  bool flag(String name) => _given.contains(name);
  String? value(String name) => _values[name];

  void done({required int maxPositional}) {
    if (positional.length > maxPositional) {
      throw PublishException('Unexpected ${positional.skip(maxPositional).join(' ')}.');
    }
  }
}
