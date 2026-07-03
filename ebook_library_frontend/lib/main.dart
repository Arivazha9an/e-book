import 'package:flutter/material.dart';
import 'package:ebook_library_frontend/core/di/injection_container.dart' as di;
import 'package:ebook_library_frontend/core/theme/app_theme.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/pages/library_shelf_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDependencies();
  runApp(const EbookLibraryApp());
}

class EbookLibraryApp extends StatelessWidget {
  const EbookLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ebook Library',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // The offline banner is embedded in LibraryShelfPage itself via the
      // NetworkInfo stream, so no ConnectivityBanner wrapper is needed here.
      home: const LibraryShelfPage(),
    );
  }
}
