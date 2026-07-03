import 'dart:async';

/// Delays invoking [run] until no new call has arrived for [delay].
/// Used to debounce the search field and to throttle how often reading
/// progress is written back to the server while a user is actively reading.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 400)});

  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
