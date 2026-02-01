import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'binary_locator.dart';
import 'process_runner.dart';
import '../features/link_grabber/data/services/link_grabber_service.dart';

final binaryLocatorProvider = Provider<BinaryLocator>((ref) => BinaryLocator());
final processRunnerProvider = Provider<ProcessRunner>((ref) => ProcessRunner());
final linkGrabberServiceProvider = Provider<LinkGrabberService>(
  (ref) => LinkGrabberService(
    ref.watch(binaryLocatorProvider),
    ref.watch(processRunnerProvider),
  ),
);
