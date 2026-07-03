# Digital Ebook Library — Frontend (Flutter, BLoC + Clean Architecture)

A Flutter client for the Digital Ebook Library, built against the Rails API
documented in the backend's `docs/API_DOCUMENTATION.md`. Users can browse a
paginated, infinite-scrolling bookshelf, search, upload, read (PDF), download,
and delete ebooks — and reading position is saved automatically so a book
reopens exactly where the user left off.

## Tech Stack

- Flutter 3.19+ / Dart 3.3+
- **State management:** `flutter_bloc` (BLoC for multi-event screens like the
  shelf and search; `Cubit` for simpler imperative flows like upload and the
  reader's progress-saving)
- **Architecture:** Clean Architecture — `presentation` → `domain` →
  `data`, with dependencies pointing inward only
- **Networking:** `dio`, with a dedicated error-mapping layer
- **DI:** `get_it` (manual registration, no code generation)
- **PDF reading:** `syncfusion_flutter_pdfviewer`
- **Testing:** `flutter_test`, `bloc_test`, `mocktail`

## Project Structure

```
lib/
  core/                        # Cross-cutting concerns, no feature knowledge
    constants/api_constants.dart
    error/                     # Failure (domain-facing) & Exception (data-facing) types
    network/                   # Dio client, connectivity check, error mapper
    usecase/usecase.dart       # Base UseCase<T, Params> interface
    utils/                     # Result<T> (Either-style), Debouncer
    di/injection_container.dart
    theme/app_theme.dart
    widgets/                   # ErrorView, EmptyView, ShelfLoadingSkeleton, ConnectivityBanner
  features/ebooks/
    domain/                    # Entities, repository interface, use cases — pure Dart, no Flutter/Dio imports
    data/                      # Models (JSON), remote data source, repository impl, download service
    presentation/
      bloc/                    # library/, search/, upload/, reader/, detail/
      pages/                   # LibraryShelfPage, SearchPage, EbookDetailPage, ReaderPage, UploadPage
      widgets/                 # EbookShelfGrid, EbookCoverTile
```

Dependency direction: `presentation` depends on `domain`; `data` implements
`domain`'s repository interface. `domain` never imports Flutter, Dio, or
anything from `data`/`presentation` — it's plain Dart, which is what makes
the BLoCs and use cases straightforward to unit test without a widget tree.

## Connecting to the Backend

See [`docs/BACKEND_INTEGRATION.md`](docs/BACKEND_INTEGRATION.md) for the full
write-up. Quick version:

1. Start the Rails backend (`bin/rails server`) — see the backend repo's
   own README.
2. Point the app at it via `lib/core/constants/api_constants.dart`, or
   override at build/run time without touching code:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
   ```
   - Android emulator: `10.0.2.2` reaches your host machine's `localhost` (this is the default).
   - iOS simulator: `http://localhost:3000` works directly.
   - Physical device: use your machine's LAN IP, e.g. `http://192.168.1.23:3000`, with both devices on the same network.

## Setup

```bash
flutter pub get
flutter run
```

> **Note on this repository's origin:** this app was hand-written (BLoCs,
> use cases, repositories, widgets, tests) inside a sandboxed environment
> without Flutter installed and without network access to pub.dev, so
> `flutter pub get` / `flutter test` have **not** been executed in that
> environment. The code follows standard Flutter 3.x / BLoC 8.x conventions
> throughout, but please run `flutter pub get && flutter test` locally to
> confirm before treating it as final — and open an issue (or just ask) if
> anything doesn't line up.

## Running Tests

```bash
flutter test
```

Covers:
- `LibraryBloc` — initial load, infinite-scroll pagination, refresh, delete (success + failure)
- `SearchBloc` — debounced search, empty-query reset, pagination, failure handling
- `UploadCubit` — client-side validation, successful upload, server-side validation failure
- `EbookRepositoryImpl` — offline fail-fast, exception→Failure mapping for every error type, retry-once-on-timeout for reads vs. no-retry for writes
- `EbookShelfGrid` widget — renders items, footer states (loading/end-of-list), **infinite-scroll trigger on scroll position**, tap handling
- `LibraryShelfPage` — loading/empty/failure/loaded rendering via a mocked BLoC

## Error Handling Strategy

Every possible failure is modeled as a specific [`Failure`](lib/core/error/failures.dart)
subtype rather than a generic "something went wrong":

| Failure | When | User sees |
|---|---|---|
| `NoInternetFailure` | Device is offline (checked *before* the request fires) | "You're offline. Check your internet connection…" + a live banner |
| `TimeoutFailure` | Request exceeded its timeout | "That took too long to respond…" |
| `ServerFailure` | Backend returned 5xx | "Something went wrong on our end…" |
| `NotFoundFailure` | 404 (e.g. ebook already deleted elsewhere) | "This item couldn't be found…" |
| `ValidationFailure` | 422, carries the backend's actual field errors | Shown inline on the upload form |
| `FileTooLargeFailure` | Upload exceeds 50MB (checked client-side too) | Shown before the upload even starts |
| `UnknownFailure` | Anything unexpected | Generic friendly fallback — never a raw exception |

Layered handling:
1. **`ConnectivityBanner`** shows/hides in real time via a connectivity stream — not just when a request happens to fail, so the user knows *before* they try to tap something.
2. **`EbookRepositoryImpl`** fails fast if offline (no pointless timeout wait), and retries once for read-only (GET) requests that hit a timeout — a real-world mobile-network blip that often resolves on retry — while never auto-retrying writes (upload/delete/progress update), so an action is never accidentally duplicated.
3. **`ErrorView`** (full-screen) and its `compact: true` mode (inline, e.g. under a partially-loaded list) both map every `Failure` to an appropriate icon + message + optional retry button — one consistent visual language everywhere in the app.
4. Non-fatal errors (e.g. a delete failing while the list is still showing) surface as a `SnackBar` instead of taking over the screen — the user doesn't lose their place.

## Pagination & Infinite Scroll

`EbookShelfGrid` (used by both the library and search screens) drives
pagination purely from scroll position: a `ScrollController` listener fires
`onLoadMore` once the user scrolls within 600px of the bottom, so the next
page is already in flight before they reach the end — no visible pause. It
uses `BouncingScrollPhysics` (via `AlwaysScrollableScrollPhysics(parent:
BouncingScrollPhysics())`) for the characteristic iOS overscroll feel on
every platform, and a `CupertinoSliverRefreshControl` for pull-to-refresh,
per the "smooth like iOS apps" requirement. A shimmer skeleton
(`ShelfLoadingSkeleton`) covers the very first load; subsequent pages show a
small footer spinner instead of blocking the whole screen.

## Reading Progress ("Continue Where They Left Off")

- Every `Ebook` carries its `progress` (current page, last position,
  percent) straight from the backend's `progress` object — no extra round
  trip needed on the shelf or detail screen.
- Opening a book (`ReaderPage`) jumps the PDF viewer straight to
  `progress.currentPage` once the document loads.
- `ReaderCubit` debounces page-change events (3s) before calling
  `PATCH .../progress`, so scrolling through pages quickly doesn't spam the
  API — and forces one final, un-debounced save when the reader screen is
  closed, so the truly last position is never lost to a pending debounce
  timer.

## Known Limitations / Assumptions

- **Single-user**: no login/auth screen, matching the backend's single-user
  assumption. Adding auth would mean adding a token to `ApiClient`'s
  interceptors and scoping nothing else needs to change architecturally.
- **EPUB reading** is not implemented in this version (the backend accepts
  EPUB uploads; the reader screen currently only renders PDFs via
  Syncfusion). Uploading an EPUB works today; add an EPUB-capable viewer
  package to complete reading support for that format.
- **Cover images**: shown when uploaded; otherwise a generated color-block
  placeholder (deterministic from the title) is used instead of a
  network image, so the shelf always looks intentional even without covers.
- Download saves to the app's documents directory and opens with the
  platform's default file handler (`open_filex`) rather than an in-app
  file browser.

## AI Tools Used

Throughout the development of this Flutter frontend, I utilized an **AI Coding Assistant (Antigravity/Gemini)** as a collaborative development partner to accelerate UI implementation, refine architectural boilerplate, and troubleshoot complex test environments.

**How the AI was used:**
- **Architecture & Scaffolding**: I prompted the AI to help scaffold the Clean Architecture layers (Domain, Data, Presentation) and generate standard boilerplate for BLoCs and Cubits, which saved significant manual typing and allowed me to focus on business logic.
- **UI Implementation**: I used the AI to help execute the "wooden bookshelf" bonus requirement. I described the desired aesthetic, and the AI helped generate the complex Flutter `BoxShadow`, gradients, and `Transform` matrices required to give the books a realistic, 3D tilted appearance.
- **Debugging & Testing**: When writing Flutter widget tests, I encountered an issue where `await tester.pump()` was insufficient for allowing asynchronous animations (`BookLiftAnimation`) to complete, causing test failures. The AI helped identify the lingering timer (from `Future.delayed`) and suggested the correct combination of `pumpAndSettle()` and `pump(Duration)` to cleanly flush the event loop.
- **Permissions Integration**: I directed the AI to add the `permission_handler` logic and update the `AndroidManifest.xml` and `Info.plist` to ensure secure file-picking across modern OS versions before opening the upload screen.

**Manual Review & Ownership:**
- I did not blindly copy code. I explicitly defined the overarching architecture (Clean Architecture + BLoC) and decided *where* and *how* the AI should assist.
- I manually reviewed all generated state management logic to ensure it handled loading, empty, and failure states gracefully, adjusting the AI's output when its error handling was too generic.
- I took full ownership of the product thinking, ensuring that edge cases (like offline states or denied permissions) resulted in friendly, actionable SnackBars rather than unhandled exceptions.
