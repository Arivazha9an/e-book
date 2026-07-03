import 'package:equatable/equatable.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

/// Fired on every keystroke — the bloc itself debounces before calling the
/// API (see [SearchBloc]), so the UI doesn't need its own debounce logic.
class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

class SearchNextPageRequested extends SearchEvent {
  const SearchNextPageRequested();
}

class SearchCleared extends SearchEvent {
  const SearchCleared();
}
