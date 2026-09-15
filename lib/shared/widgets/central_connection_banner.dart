import 'package:flutter/material.dart';

import '../../backend/resilience/central_connection_status.dart';
import '../../backend/resilience/central_connection_tracker.dart';
import '../../backend/resilience/central_failure_kind.dart';
import '../../backend/resilience/central_resilience_runtime.dart';

/// Adds a non-invasive central connection indicator over an existing FleetIQ
/// screen without changing that screen's layout or navigation structure.
class CentralConnectionBoundary extends StatelessWidget {
  const CentralConnectionBoundary({
    super.key,
    required this.child,
    this.tracker,
  });

  final Widget child;
  final CentralConnectionTracker? tracker;

  @override
  Widget build(BuildContext context) {
    final connectionTracker =
        tracker ?? CentralResilienceRuntime.instance.tracker;
    return AnimatedBuilder(
      animation: connectionTracker,
      builder: (context, _) {
        final status = connectionTracker.status;
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (_shouldShow(status))
              Align(
                alignment: Alignment.topCenter,
                child: SafeArea(
                  bottom: false,
                  child: _CentralConnectionBanner(status: status),
                ),
              ),
          ],
        );
      },
    );
  }

  bool _shouldShow(CentralConnectionStatus status) =>
      status.state == CentralConnectionState.offline ||
      status.state == CentralConnectionState.degraded;
}

class _CentralConnectionBanner extends StatelessWidget {
  const _CentralConnectionBanner({required this.status});

  final CentralConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final offline = status.state == CentralConnectionState.offline;
    final scheme = Theme.of(context).colorScheme;
    final background = offline
        ? scheme.errorContainer
        : scheme.tertiaryContainer;
    final foreground = offline
        ? scheme.onErrorContainer
        : scheme.onTertiaryContainer;

    return Material(
      color: background,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              offline ? Icons.cloud_off_outlined : Icons.cloud_sync_outlined,
              size: 18,
              color: foreground,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                offline
                    ? 'You’re offline • showing saved FleetIQ data where available. Supported changes will sync when you reconnect.'
                    : _degradedLabel(status.failureKind),
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _degradedLabel(CentralFailureKind kind) => switch (kind) {
    CentralFailureKind.authentication => 'Central authentication problem',
    CentralFailureKind.authorization => 'Central permission problem',
    CentralFailureKind.server => 'Central service problem',
    _ => 'Central connection degraded',
  };
}
