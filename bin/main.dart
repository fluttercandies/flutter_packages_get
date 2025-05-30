import 'dart:io';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:flutter_packages_get/arg/arg_parser.dart';
import 'package:flutter_packages_get/arg/delete_lock.dart';
import 'package:flutter_packages_get/arg/help.dart';
import 'package:flutter_packages_get/arg/sdk.dart';
import 'package:io/ansi.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> arguments) async {
  final Help help = Help();
  final Sdk sdk = Sdk();
  final DeleteLock deleteLock = DeleteLock();
  parseArgs(arguments);

  if (help.value!) {
    print(green.wrap(parser.usage));
    return;
  }
  final String executable = sdk.value == null
      ? 'flutter'
      : path.join(
          sdk.value!, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');
  processRun(
    executable: executable,
    arguments: 'packages get',
    runInShell: true,
  );

  clearPluginManager();

  final PackageGraph packageGraph = await PackageGraph.forThisPackage();

  final Iterable<PackageNode> packages = packageGraph.allPackages.values;

  for (final PackageNode item in packages) {
    if (!item.isRoot &&
        item.dependencyType == DependencyType.path &&
        item.path.startsWith(
          packageGraph.root.path,
        )) {
      await _packagesGet(
        item,
        executable,
        deleteLock.value ?? false,
      );
    }
  }

  _packagesGet(
    packageGraph.root,
    executable,
    deleteLock.value ?? false,
  );
}

Future<void> _packagesGet(
  PackageNode item,
  String executable,
  bool deleteLock,
) async {
  if (deleteLock) {
    deleteFile(path.join(item.path, '.packages'));

    deleteFile(path.join(item.path, 'pubspec.lock'));
  }

  final String toolsPath = path.join(item.path, 'tools', 'analyzer_plugin');
  if (Directory(toolsPath).existsSync()) {
    processRun(
      executable: executable,
      arguments: 'packages get $toolsPath',
      runInShell: true,
    );

    _packagesGet(
      (await PackageGraph.forPath(toolsPath)).root,
      executable,
      deleteLock,
    );
  }

  processRun(
    executable: executable,
    arguments: 'packages get ${item.path}',
    runInShell: true,
  );

  processRun(
    executable: executable,
    arguments: 'clean ${item.path}',
    runInShell: true,
  );

  if (deleteLock) {
    deleteFile(path.join(item.path, '.packages'));

    deleteFile(path.join(item.path, 'pubspec.lock'));
  }

  processRun(
    executable: executable,
    arguments: 'packages get ${item.path}',
    runInShell: true,
  );
}

void processRun(
    {required String executable,
    required String arguments,
    bool runInShell = false}) {
  final ProcessResult result = Process.runSync(
    executable,
    arguments.split(' '),
    runInShell: runInShell,
  );
  if (result.exitCode != 0) {
    throw Exception(result.stderr);
  }
  print('${result.stdout}\n');
}

void deleteFile(String fileName) {
  final File file = File(fileName);
  if (file.existsSync()) {
    print('delete $fileName');
    file.deleteSync();
  }
}

void clearPluginManager() {
  //final String os = Platform.operatingSystem;
  String? home;
  final Map<String, String> envVars = Platform.environment;
  if (Platform.isMacOS) {
    home = envVars['HOME'];
  } else if (Platform.isLinux) {
    home = envVars['HOME'];
  } else if (Platform.isWindows) {
    home = envVars['UserProfile'];
  }

  if (home != null) {
    Directory? directory;
    // macos:  `/Users/user_name/.dartServer/.plugin_manager/`

    // windows: `C:\Users\user_name\AppData\Local\.dartServer\.plugin_manager\`
    if (Platform.isMacOS) {
      directory = Directory(path.join(home, '.dartServer', '.plugin_manager'));
    } else if (Platform.isLinux) {
      directory = Directory(path.join(home, '.dartServer', '.plugin_manager'));
    } else if (Platform.isWindows) {
      directory = Directory(path.join(
          home, 'AppData', 'Local', '.dartServer', '.plugin_manager'));
    }

    if (directory != null && directory.existsSync()) {
      print('clear plugin_manager cache\n');
      directory.deleteSync(recursive: true);
    }
  }
}
