import 'package:flutter/material.dart';
import 'package:ebook_library_frontend/core/error/failures.dart';

/// A single, consistent way to present any [Failure] to the user, with an
/// icon and copy tailored to the failure type (offline vs. server error vs.
/// not found, etc.) plus an optional retry button.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.failure,
    this.onRetry,
    this.compact = false,
  });

  final Failure failure;
  final VoidCallback? onRetry;

  /// Compact mode is used inline (e.g. a footer row under a partially
  /// loaded list); non-compact fills the available space, used for
  /// full-screen failures.
  final bool compact;

  IconData get _icon => switch (failure) {
        NoInternetFailure() => Icons.wifi_off_rounded,
        TimeoutFailure() => Icons.hourglass_bottom_rounded,
        ServerFailure() => Icons.cloud_off_rounded,
        NotFoundFailure() => Icons.search_off_rounded,
        ValidationFailure() => Icons.error_outline_rounded,
        FileTooLargeFailure() => Icons.file_present_rounded,
        UnknownFailure() => Icons.error_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 18, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Flexible(
              child: Text(failure.message, style: theme.textTheme.bodySmall),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 56, color: theme.colorScheme.error.withOpacity(0.8)),
            const SizedBox(height: 16),
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
