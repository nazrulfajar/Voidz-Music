import 'package:logger/logger.dart';

/// Shared, terse logger for non-UI diagnostics.
///
/// New code must not call `print` (TASK-003); use this logger so levels and
/// formatting stay consistent across features.
final Logger appLogger = Logger(
  printer: SimplePrinter(printTime: false),
);
