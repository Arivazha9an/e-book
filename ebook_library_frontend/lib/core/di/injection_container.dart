import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:ebook_library_frontend/core/network/api_client.dart';
import 'package:ebook_library_frontend/core/network/network_info.dart';
import 'package:ebook_library_frontend/features/ebooks/data/datasources/ebook_remote_data_source.dart';
import 'package:ebook_library_frontend/features/ebooks/data/repositories/ebook_repository_impl.dart';
import 'package:ebook_library_frontend/features/ebooks/data/services/ebook_download_service.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/repositories/ebook_repository.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/delete_ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/get_download_url.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/get_ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/get_ebooks.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/get_progress.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/search_ebooks.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/update_progress.dart';
import 'package:ebook_library_frontend/features/ebooks/domain/usecases/upload_ebook.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/bloc/library/library_bloc.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/bloc/search/search_bloc.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/bloc/upload/upload_cubit.dart';

final GetIt sl = GetIt.instance;

/// Wires up every layer, outer-in: core/network -> data -> domain ->
/// presentation. Called once from `main()`.
///
/// Kept intentionally simple (no code-generation like `injectable`) so it's
/// easy to read top-to-bottom and easy to override in tests via
/// `sl.registerSingleton(...)` before `runApp`.
Future<void> initDependencies({String? apiBaseUrlOverride}) async {
  // ---- Core ----
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient.create(baseUrlOverride: apiBaseUrlOverride),
  );

  // ---- Data ----
  sl.registerLazySingleton<EbookRemoteDataSource>(
    () => EbookRemoteDataSourceImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton<EbookRepository>(
    () => EbookRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => EbookDownloadService(sl<ApiClient>().dio));

  // ---- Domain use cases ----
  sl.registerLazySingleton(() => GetEbooks(sl()));
  sl.registerLazySingleton(() => GetEbook(sl()));
  sl.registerLazySingleton(() => SearchEbooks(sl()));
  sl.registerLazySingleton(() => UploadEbook(sl()));
  sl.registerLazySingleton(() => DeleteEbook(sl()));
  sl.registerLazySingleton(() => GetDownloadUrl(sl()));
  sl.registerLazySingleton(() => GetProgress(sl()));
  sl.registerLazySingleton(() => UpdateProgress(sl()));

  // ---- Presentation ----
  // Factories: a fresh bloc instance per screen visit (not shared global
  // state), which is what you want for screen-scoped state like this.
  sl.registerFactory(() => LibraryBloc(getEbooks: sl(), deleteEbook: sl()));
  sl.registerFactory(() => SearchBloc(searchEbooks: sl()));
  sl.registerFactory(() => UploadCubit(uploadEbook: sl()));
  // ReaderCubit is intentionally NOT registered here since it needs a
  // per-ebook `ebookId`/`initialPage` — it's constructed directly on the
  // reader page with `sl<UpdateProgress>()`.
}

/// Clears all registrations — call from `tearDown()` between test files
/// that each call `initDependencies()` with mocks.
Future<void> resetDependencies() => sl.reset();
