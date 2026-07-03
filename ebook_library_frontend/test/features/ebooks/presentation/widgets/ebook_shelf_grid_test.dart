import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/entities/ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/widgets/ebook_shelf_grid.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/widgets/realistic_book_tile.dart';

import '../../../../helpers/test_fixtures.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders one tile per ebook', (tester) async {
    final ebooks = List.generate(6, (i) => buildEbook(id: i, title: 'Book $i'));

    await tester.pumpWidget(_wrap(EbookShelfGrid(
      ebooks: ebooks,
      hasNextPage: false,
      isLoadingMore: false,
      onLoadMore: () {},
      onRefresh: () async {},
      onTapEbook: (_) {},
    )));

    expect(find.text('Book 0'), findsWidgets);
    expect(find.text('Book 5'), findsWidgets);
  });

  testWidgets('shows "reached the end" footer when there is no next page', (tester) async {
    await tester.pumpWidget(_wrap(EbookShelfGrid(
      ebooks: [buildEbook()],
      hasNextPage: false,
      isLoadingMore: false,
      onLoadMore: () {},
      onRefresh: () async {},
      onTapEbook: (_) {},
    )));

    expect(find.textContaining("reached the end"), findsOneWidget);
  });

  testWidgets('shows a footer spinner while loading the next page', (tester) async {
    await tester.pumpWidget(_wrap(EbookShelfGrid(
      ebooks: List.generate(6, (i) => buildEbook(id: i)),
      hasNextPage: true,
      isLoadingMore: true,
      onLoadMore: () {},
      onRefresh: () async {},
      onTapEbook: (_) {},
    )));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('calls onLoadMore once the user scrolls near the bottom', (tester) async {
    var loadMoreCalls = 0;
    // Enough items to make the grid scrollable within the test viewport.
    final ebooks = List.generate(30, (i) => buildEbook(id: i, title: 'Book $i'));

    await tester.pumpWidget(_wrap(EbookShelfGrid(
      ebooks: ebooks,
      hasNextPage: true,
      isLoadingMore: false,
      onLoadMore: () => loadMoreCalls++,
      onRefresh: () async {},
      onTapEbook: (_) {},
    )));

    // Drag the scroll view all the way to the bottom.
    await tester.fling(find.byType(CustomScrollView), const Offset(0, -4000), 2000);
    await tester.pumpAndSettle();

    expect(loadMoreCalls, greaterThan(0));
  });

  testWidgets('does not call onLoadMore when there is no next page', (tester) async {
    var loadMoreCalls = 0;
    final ebooks = List.generate(30, (i) => buildEbook(id: i, title: 'Book $i'));

    await tester.pumpWidget(_wrap(EbookShelfGrid(
      ebooks: ebooks,
      hasNextPage: false,
      isLoadingMore: false,
      onLoadMore: () => loadMoreCalls++,
      onRefresh: () async {},
      onTapEbook: (_) {},
    )));

    await tester.fling(find.byType(CustomScrollView), const Offset(0, -4000), 2000);
    await tester.pumpAndSettle();

    expect(loadMoreCalls, 0);
  });

  testWidgets('tapping a tile invokes onTapEbook with the right ebook', (tester) async {
    Ebook? tapped;
    final ebook = buildEbook(id: 42, title: 'Domain-Driven Design');

    await tester.pumpWidget(_wrap(EbookShelfGrid(
      ebooks: [ebook],
      hasNextPage: false,
      isLoadingMore: false,
      onLoadMore: () {},
      onRefresh: () async {},
      onTapEbook: (e) => tapped = e,
    )));

    await tester.tap(find.byType(RealisticBookTile));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    expect(tapped?.id, 42);
  });
}
