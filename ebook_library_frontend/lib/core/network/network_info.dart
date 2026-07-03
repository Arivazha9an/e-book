import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ebook_library_frontend/core/constants/api_constants.dart';

/// Thin wrapper around `connectivity_plus` so the rest of the app depends on
/// a simple interface (and so tests can mock it) instead of the package
/// directly.
abstract class NetworkInfo {
  Future<bool> get isConnected;

  /// Stream of connectivity changes, used to show/hide the offline banner
  /// in real time rather than only checking at request time.
  Stream<bool> get onConnectivityChanged;
}

/// Real implementation that combines two checks:
/// 1. Device-level connectivity via `connectivity_plus` (WiFi / mobile data).
/// 2. A TCP socket ping to the backend host so we also detect the case where
///    the device has WiFi but the local dev server has been killed.
///
/// The stream merges `connectivity_plus` events with a 5-second periodic poll
/// so the banner appears within ~5 seconds of the server going down.
class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  /// Extracts host and port from [ApiConstants.baseUrl].
  /// Falls back to 'localhost' / 80 if parsing fails.
  static (String host, int port) _parseBaseUrl() {
    try {
      final uri = Uri.parse(ApiConstants.baseUrl);
      return (uri.host, uri.port > 0 ? uri.port : 80);
    } catch (_) {
      return ('localhost', 80);
    }
  }

  /// Returns `true` if:
  /// - device has a network interface (WiFi / mobile), AND
  /// - the backend host responds on its port within 3 seconds.
  @override
  Future<bool> get isConnected async {
    // Step 1: quick device-level check
    final results = await _connectivity.checkConnectivity();
    final hasInterface = results.any((r) => r != ConnectivityResult.none);
    if (!hasInterface) return false;

    // Step 2: TCP reachability check against the backend
    return _canReachBackend();
  }

  Future<bool> _canReachBackend() async {
    try {
      final (host, port) = _parseBaseUrl();
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Merges three event sources:
  /// 1. An immediate check at subscription time.
  /// 2. `connectivity_plus` change events.
  /// 3. A 5-second periodic poll (catches server-down without a network change).
  @override
  Stream<bool> get onConnectivityChanged {
    late StreamController<bool> controller;
    StreamSubscription<List<ConnectivityResult>>? connectivitySub;
    Timer? pollTimer;

    Future<void> emitCurrentState() async {
      try {
        final connected = await isConnected;
        if (!controller.isClosed) controller.add(connected);
      } catch (_) {
        if (!controller.isClosed) controller.add(false);
      }
    }

    controller = StreamController<bool>(
      onListen: () {
        // Emit immediately on first subscription
        emitCurrentState();

        // Listen for device connectivity changes
        connectivitySub = _connectivity.onConnectivityChanged.listen(
          (_) => emitCurrentState(),
        );

        // Poll every 5 seconds to detect server going down
        pollTimer = Timer.periodic(
          const Duration(seconds: 5),
          (_) => emitCurrentState(),
        );
      },
      onCancel: () {
        connectivitySub?.cancel();
        pollTimer?.cancel();
      },
    );

    return controller.stream;
  }
}
