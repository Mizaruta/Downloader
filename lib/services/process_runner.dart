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
}
