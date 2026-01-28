import 'dart:convert';
import 'dart:io';
import '../core/logger/logger_service.dart';

class ProcessRunner {
  Future<Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    LoggerService.debug('Starting process: $executable ${arguments.join(' ')}');
    return await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: true, // Use shell to resolve PATH
    );
  }

  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    LoggerService.debug('Running process: $executable ${arguments.join(' ')}');
    return await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: true, // Use shell to resolve PATH
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
  }

  Future<void> kill(Process process) async {
    if (Platform.isWindows) {
      // Use taskkill to kill the process tree (/T) forcefully (/F)
      try {
        await Process.run('taskkill', [
          '/F',
          '/T',
          '/PID',
          process.pid.toString(),
        ]);
        LoggerService.debug('Killed process tree for PID: ${process.pid}');
      } catch (e) {
        LoggerService.w('Failed to kill process tree: $e');
        process.kill(); // Fallback
      }
    } else {
      process.kill();
    }
  }
}
