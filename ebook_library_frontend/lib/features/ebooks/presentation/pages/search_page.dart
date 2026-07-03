import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ebook_library_frontend/core/di/injection_container.dart';
import 'package:ebook_library_frontend/core/widgets/empty_view.dart';
import 'package:ebook_library_frontend/core/widgets/error_view.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/bloc/search/search_bloc.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/pages/ebook_detail_page.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/widgets/ebook_shelf_grid.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SearchBloc>(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search by title, author, or file name',
            border: InputBorder.none,
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => value.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _controller.clear();
                        context.read<SearchBloc>().add(const SearchCleared());
                      },
                    ),
            ),
          ),
          onChanged: (value) => context.read<SearchBloc>().add(SearchQueryChanged(value)),
        ),
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state.query.isEmpty) {
            return const EmptyView(
              icon: Icons.search_rounded,
              title: 'Search your library',
              subtitle: 'Start typing a title, author, or file name.',
            );
          }

          if (state.status == SearchStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == SearchStatus.failure) {
            return ErrorView(
              failure: state.failure!,
              onRetry: () => context.read<SearchBloc>().add(SearchQueryChanged(state.query)),
            );
          }

          if (state.isEmptyResult) {
            return EmptyView(
              icon: Icons.menu_book_outlined,
              title: 'No results for "${state.query}"',
              subtitle: 'Try a different title, author, or file name.',
            );
          }

          return EbookShelfGrid(
            ebooks: state.results,
            hasNextPage: state.hasNextPage,
            isLoadingMore: state.status == SearchStatus.loadingMore,
            onLoadMore: () => context.read<SearchBloc>().add(const SearchNextPageRequested()),
            onRefresh: () async {
              context.read<SearchBloc>().add(SearchQueryChanged(state.query));
            },
            onTapEbook: (ebook) => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EbookDetailPage(ebookId: ebook.id, initial: ebook)),
            ),
          );
        },
      ),
    );
  }
}
