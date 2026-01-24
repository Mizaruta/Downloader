import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the URL that triggered the app launch (if any).
final launchUrlProvider = StateProvider<String?>((ref) => null);
