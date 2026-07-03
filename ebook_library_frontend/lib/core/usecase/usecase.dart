import 'package:ebook_library_frontend/core/utils/result.dart';

/// A use case that takes [Params] and returns a [Result] wrapping [T].
/// Every interactor in `domain/usecases` implements this so the
/// presentation layer can treat them uniformly.
abstract class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// Marker for use cases that don't need any parameters (e.g. "get health").
class NoParams {
  const NoParams();
}
