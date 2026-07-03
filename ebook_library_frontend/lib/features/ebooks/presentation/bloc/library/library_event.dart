import 'package:equatable/equatable.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/repositories/ebook_repository.dart';

sealed class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once when the shelf screen first mounts.
class LibraryStarted extends LibraryEvent {
  const LibraryStarted();
}

/// Pull-to-refresh: reloads page 1 without showing the full-screen loader.
class LibraryRefreshed extends LibraryEvent {
  const LibraryRefreshed();
}

/// Fired by the scroll listener when the user nears the bottom of the
/// shelf — loads the next page and appends it.
class LibraryNextPageRequested extends LibraryEvent {
  const LibraryNextPageRequested();
}

class LibrarySortChanged extends LibraryEvent {
  const LibrarySortChanged(this.sort);
  final EbookSort sort;

  @override
  List<Object?> get props => [sort];
}

class LibraryFileTypeFilterChanged extends LibraryEvent {
  const LibraryFileTypeFilterChanged(this.fileType);
  final String? fileType;

  @override
  List<Object?> get props => [fileType];
}

class LibraryEbookDeleted extends LibraryEvent {
  const LibraryEbookDeleted(this.ebookId);
  final int ebookId;

  @override
  List<Object?> get props => [ebookId];
}
