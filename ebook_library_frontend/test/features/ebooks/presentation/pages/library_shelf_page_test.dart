import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ebook_library_frontend/core/error/failures.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/bloc/library/library_bloc.dart';

import '../../../../helpers/test_fixtures.dart';

class MockLibraryBloc extends MockBloc<LibraryEvent, LibraryState> implements LibraryBloc {}

void main() {
  late MockLibraryBloc bloc;

  setUp(() {
    bloc = MockLibraryBloc();
  });

  Widget wrap() => MaterialApp(
        home: BlocProvider<LibraryBloc>.value(
          value: bloc,
          child: Builder(
            builder: (context) => Scaffold(
              body: BlocBuilder<LibraryBloc, LibraryState>(
                builder: (context, state) {
                  if (state.status == LibraryStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == LibraryStatus.failure) {
                    return Center(child: Text(state.failure!.message));
                  }
                  if (state.isEmpty) {
                    return const Center(child: Text('Your shelf is empty'));
                  }
                  return ListView(
                    children: state.ebooks.map((e) => Text(e.title)).toList(),
                  );
                },
              ),
            ),
          ),
        ),
      );

  testWidgets('shows a loading indicator in the loading state', (tester) async {
    when(() => bloc.state).thenReturn(const LibraryState(status: LibraryStatus.loading));

    await tester.pumpWidget(wrap());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no ebooks', (tester) async {
    when(() => bloc.state).thenReturn(const LibraryState(status: LibraryStatus.success, ebooks: []));

    await tester.pumpWidget(wrap());

    expect(find.text('Your shelf is empty'), findsOneWidget);
  });

  testWidgets('shows a friendly message in the failure state', (tester) async {
    when(() => bloc.state).thenReturn(
      const LibraryState(status: LibraryStatus.failure, failure: NoInternetFailure()),
    );

    await tester.pumpWidget(wrap());

    expect(find.textContaining("offline"), findsOneWidget);
  });

  testWidgets('renders each ebook title when loaded', (tester) async {
    when(() => bloc.state).thenReturn(LibraryState(
      status: LibraryStatus.success,
      ebooks: [buildEbook(title: 'Clean Code'), buildEbook(id: 2, title: 'Refactoring')],
    ));

    await tester.pumpWidget(wrap());

    expect(find.text('Clean Code'), findsOneWidget);
    expect(find.text('Refactoring'), findsOneWidget);
  });
}
