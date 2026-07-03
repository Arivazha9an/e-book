import 'dart:async';
import 'package:ebook_library_frontend/core/error/failures.dart';
import 'package:ebook_library_frontend/core/network/network_info.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/widgets/book_shelf_background.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/widgets/wooden_self.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ebook_library_frontend/core/di/injection_container.dart';
import 'package:ebook_library_frontend/core/widgets/error_view.dart';
import 'package:ebook_library_frontend/core/widgets/shelf_loading_skeleton.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/repositories/ebook_repository.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/bloc/library/library_bloc.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/pages/ebook_detail_page.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/pages/upload_page.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/widgets/book_shelf_layout.dart';

const Color _darkWood = Color(0xFF6B4226);

class LibraryShelfPage extends StatelessWidget {
  const LibraryShelfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LibraryBloc>()..add(const LibraryStarted()),
      child: const _LibraryShelfView(),
    );
  }
}

class _LibraryShelfView extends StatefulWidget {
  const _LibraryShelfView();

  @override
  State<_LibraryShelfView> createState() => _LibraryShelfViewState();
}

class _LibraryShelfViewState extends State<_LibraryShelfView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';

  // Offline banner state — driven by NetworkInfo stream so it updates
  // the moment the backend goes down, not only when a request fails.
  bool _isOffline = false;
  StreamSubscription<bool>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    final networkInfo = sl<NetworkInfo>();
    // Check immediately
    networkInfo.isConnected.then((connected) {
      if (mounted) setState(() => _isOffline = !connected);
    });
    // Then track changes
    _connectivitySub = networkInfo.onConnectivityChanged.listen((connected) {
      if (mounted) setState(() => _isOffline = !connected);
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Filter books locally for instant, blink-free search.
  List<Ebook> _filterBooks(List<Ebook> ebooks) {
    if (_searchQuery.isEmpty) return ebooks;
    final q = _searchQuery.toLowerCase();
    return ebooks.where((book) {
      return book.title.toLowerCase().contains(q) ||
          book.displayAuthor.toLowerCase().contains(q);
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value.trim());
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    _searchFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _darkWood,
        foregroundColor: Colors.white,
        onPressed: () async {
          // Request permissions before opening the upload screen
          final storageStatus = await Permission.storage.request();
          // Android 13+ requires photos permission for images
          final photosStatus = await Permission.photos.request();

          if (storageStatus.isPermanentlyDenied ||
              photosStatus.isPermanentlyDenied) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Storage permission is required to upload books. Please enable it in settings.')),
              );
              await openAppSettings();
            }
            return;
          }

          if (context.mounted) {
            final uploaded = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const UploadPage()),
            );
            if (uploaded == true && context.mounted) {
              context.read<LibraryBloc>().add(const LibraryRefreshed());
            }
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add book'),
      ),
      body: BookshelfBackground(
        child: BlocConsumer<LibraryBloc, LibraryState>(
          listenWhen: (previous, current) =>
              current.failure != null && previous.failure != current.failure,
          listener: (context, state) {
            // Only show a snackbar for non-connectivity failures while books
            // are already loaded. Connectivity failures are handled by the
            // offline banner that appears below the app bar.
            if (state.status == LibraryStatus.success &&
                state.failure != null &&
                state.failure is! NoInternetFailure &&
                state.failure is! TimeoutFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.failure!.message)));
            }
          },
          builder: (context, state) {
            switch (state.status) {
              case LibraryStatus.initial:
              case LibraryStatus.loading:
                return _buildShellWithSlivers(
                  context,
                  state,
                  body: const SliverFillRemaining(
                    child: ShelfLoadingSkeleton(),
                  ),
                );

              case LibraryStatus.failure:
                return _buildShellWithSlivers(
                  context,
                  state,
                  body: SliverFillRemaining(
                    child: ErrorView(
                      failure: state.failure!,
                      onRetry: () => context
                          .read<LibraryBloc>()
                          .add(const LibraryStarted()),
                    ),
                  ),
                );

              case LibraryStatus.success:
              case LibraryStatus.loadingMore:
              case LibraryStatus.refreshing:
                final filteredBooks = _filterBooks(state.ebooks);
                return _buildShellWithSlivers(
                  context,
                  state,
                  body: _buildBookShelf(context, state, filteredBooks),
                );
            }
          },
        ),
      ),
    );
  }

  /// Builds the entire CustomScrollView with the SliverAppBar + search
  /// and delegates the body content to the [body] sliver.
  Widget _buildShellWithSlivers(
    BuildContext context,
    LibraryState state, {
    required Widget body,
  }) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        // ─── Premium Sliver App Bar ───
        SliverAppBar(
          expandedHeight: 140,
          floating: true,
          snap: true,
          pinned: true,
          backgroundColor: _darkWood,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.black54,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: EdgeInsets.zero,
            expandedTitleScale: 1,
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF8B5E3C),
                    _darkWood,
                  ],
                ),
              ),
            ),
          ),
          title: const Text(
            'My Library',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            // Sort menu
            BlocBuilder<LibraryBloc, LibraryState>(
              buildWhen: (previous, current) => previous.sort != current.sort,
              builder: (context, state) => PopupMenuButton<EbookSort>(
                icon: const Icon(Icons.sort_rounded, color: Colors.white70),
                tooltip: 'Sort',
                initialValue: state.sort,
                onSelected: (sort) =>
                    context.read<LibraryBloc>().add(LibrarySortChanged(sort)),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                      value: EbookSort.recent, child: Text('Recently added')),
                  PopupMenuItem(
                      value: EbookSort.recentlyRead,
                      child: Text('Recently read')),
                  PopupMenuItem(
                      value: EbookSort.title, child: Text('Title (A–Z)')),
                  PopupMenuItem(
                      value: EbookSort.author, child: Text('Author (A–Z)')),
                ],
              ),
            ),
            const SizedBox(width: 4),
          ],
          // ─── Search bar pinned at bottom of SliverAppBar ───
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              color: _darkWood.withOpacity(0.85),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: CupertinoSearchTextField(
                controller: _searchController,
                focusNode: _searchFocus,
                style: const TextStyle(color: Colors.white),
                placeholderStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                ),
                placeholder: 'Search your library',
                prefixIcon: Icon(
                  CupertinoIcons.search,
                  color: Colors.white.withOpacity(0.5),
                ),
                suffixIcon: const Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: Colors.white54,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                onChanged: _onSearchChanged,
                onSuffixTap: _clearSearch,
              ),
            ),
          ),
        ),

        // Pull-to-refresh
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            context.read<LibraryBloc>().add(const LibraryRefreshed());
            await Future<void>.delayed(const Duration(milliseconds: 300));
          },
        ),

        // ── Offline banner (below app bar, above books) ───────────────────
        // Slides in/out with AnimatedSize so it doesn't cause a jarring jump.
        SliverToBoxAdapter(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isOffline
                ? Material(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 18,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No server connection — books shown from last sync',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),

        // Body content
        body,
      ],
    );
  }

  /// Builds the wooden bookshelf rows with books.
  Widget _buildBookShelf(
    BuildContext context,
    LibraryState state,
    List<Ebook> books,
  ) {
    if (books.isEmpty && _searchQuery.isNotEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Colors.black.withOpacity(0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'No books match "$_searchQuery"',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (books.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: 64,
                color: Colors.black.withOpacity(0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Your shelf is empty',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.5),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap "Add book" to upload your first ebook.',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isTablet = MediaQuery.of(context).size.width > 600;
    final crossAxisCount = isTablet ? 5 : 3;
    final rowCount = (books.length / crossAxisCount).ceil();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, rowIndex) {
          final startIndex = rowIndex * crossAxisCount;
          final endIndex = (startIndex + crossAxisCount > books.length)
              ? books.length
              : startIndex + crossAxisCount;
          final rowBooks = books.sublist(startIndex, endIndex);

          return _ShelfRow(
            rowBooks: rowBooks,
            crossAxisCount: crossAxisCount,
            allBooks: state.ebooks,
            busyIds: state.deletingIds,
            onTapEbook: (ebook) async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      EbookDetailPage(ebookId: ebook.id, initial: ebook),
                ),
              );
              if (context.mounted) {
                context.read<LibraryBloc>().add(const LibraryRefreshed());
              }
            },
            onDeleteEbook: (ebook) =>
                context.read<LibraryBloc>().add(LibraryEbookDeleted(ebook.id)),
          );
        },
        childCount: rowCount,
      ),
    );
  }
}

/// A single shelf row: full-width wooden ledge with books on top.
class _ShelfRow extends StatelessWidget {
  const _ShelfRow({
    required this.rowBooks,
    required this.crossAxisCount,
    required this.allBooks,
    required this.busyIds,
    required this.onTapEbook,
    required this.onDeleteEbook,
  });

  final List<Ebook> rowBooks;
  final int crossAxisCount;
  final List<Ebook> allBooks;
  final Set<int> busyIds;
  final void Function(Ebook) onTapEbook;
  final void Function(Ebook) onDeleteEbook;

  Future<void> _confirmDelete(BuildContext context, Ebook ebook) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this ebook?'),
        content: Text(
            '"${ebook.title}" will be permanently removed from your library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) onDeleteEbook(ebook);
  }

  @override
  Widget build(BuildContext context) {
    return WoodenShelf(
      child: BookshelfLayout(
        books: rowBooks,
        busyIds: busyIds,
        onTap: onTapEbook,
        onLongPress: (ebook) => _confirmDelete(context, ebook),
      ),
    );
  }
}
