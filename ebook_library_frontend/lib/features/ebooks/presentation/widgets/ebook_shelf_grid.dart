import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ebook_library_frontend/core/error/failures.dart';
import 'package:ebook_library_frontend/core/widgets/error_view.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/widgets/book_shelf_layout.dart';

/// The core "shelf" grid used by both the library and search screens.
///
/// - **Infinite scroll**: a listener on the [ScrollController] fires
///   [onLoadMore] once the user scrolls within [_loadMoreThreshold] of the
///   bottom, so the next page is already loading before they hit the end —
///   no visible pause, matching how most polished iOS apps paginate.
/// - **Feel**: [BouncingScrollPhysics] (wrapped so it still works well on
///   Android) gives the characteristic iOS overscroll bounce instead of the
///   Android glow effect, per the "smooth like iOS apps" requirement.
/// - **Pull-to-refresh**: wrapped in a [CupertinoSliverRefreshControl] for
///   the same iOS-native feel while staying cross-platform.
class EbookShelfGrid extends StatefulWidget {
  const EbookShelfGrid({
    super.key,
    required this.ebooks,
    required this.hasNextPage,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onRefresh,
    required this.onTapEbook,
    this.onDeleteEbook,
    this.busyIds = const {},
    this.loadMoreFailure,
    this.onRetryLoadMore,
  });

  final List<Ebook> ebooks;
  final bool hasNextPage;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final void Function(Ebook ebook) onTapEbook;
  final void Function(Ebook ebook)? onDeleteEbook;
  final Set<int> busyIds;
  final Failure? loadMoreFailure;
  final VoidCallback? onRetryLoadMore;

  @override
  State<EbookShelfGrid> createState() => _EbookShelfGridState();
}

class _EbookShelfGridState extends State<EbookShelfGrid> {
  final ScrollController _controller = ScrollController();
  static const _loadMoreThreshold = 600.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!widget.hasNextPage || widget.isLoadingMore) return;
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      widget.onLoadMore();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

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

    if (confirmed == true) widget.onDeleteEbook?.call(ebook);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate how many books per row
    final isTablet = MediaQuery.of(context).size.width > 600;
    final crossAxisCount = isTablet ? 5 : 3;
    final rowCount = (widget.ebooks.length / crossAxisCount).ceil();

    return Container(
      // The background of the entire bookcase
      color: const Color(0xFFcba87c),
      child: CustomScrollView(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: widget.onRefresh),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, rowIndex) {
                final startIndex = rowIndex * crossAxisCount;
                final endIndex =
                    (startIndex + crossAxisCount > widget.ebooks.length)
                        ? widget.ebooks.length
                        : startIndex + crossAxisCount;
                final rowBooks = widget.ebooks.sublist(startIndex, endIndex);

                return Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // The full-width shelf ledge
                    Container(
                      height: 28,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFa17448),
                        border: Border(
                          top: BorderSide(
                              color: const Color(0xFFd4b18c),
                              width: 2), // Highlight edge
                          bottom: BorderSide(
                              color: Colors.black.withOpacity(0.5),
                              width: 4), // Deep shadow
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                    // The books on this shelf
                    Padding(
                      // Add padding to raise books slightly above the shelf's shadow/edge
                      padding: const EdgeInsets.only(
                          bottom: 12, left: 16, right: 16, top: 24),
                      child: BookshelfLayout(
                        books: rowBooks,
                        busyIds: widget.busyIds,
                        onTap: widget.onTapEbook,
                        onLongPress: widget.onDeleteEbook == null
                            ? (_) {}
                            : (ebook) => _confirmDelete(context, ebook),
                      ),
                    ),
                  ],
                );
              },
              childCount: rowCount == 0 && widget.isLoadingMore
                  ? 0
                  : (rowCount == 0 ? 1 : rowCount),
            ),
          ),
          SliverToBoxAdapter(child: _buildFooter(context)),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (widget.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (widget.loadMoreFailure != null) {
      return ErrorView(
        failure: widget.loadMoreFailure!,
        compact: true,
        onRetry: widget.onRetryLoadMore,
      );
    }

    if (!widget.hasNextPage && widget.ebooks.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            "You've reached the end of your library",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ),
      );
    }

    return const SizedBox(height: 24);
  }
}
