<div align="center">

# 📚 Digital Ebook Library

A full-stack digital ebook library — **Ruby on Rails API** backend + **Flutter** cross-platform frontend — featuring a custom wooden bookshelf UI, offline-aware reading progress sync, and clean, testable architecture.

[![Ruby](https://img.shields.io/badge/Ruby-3.2-CC342D?logo=ruby&logoColor=white)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-7.1-CC0000?logo=rubyonrails&logoColor=white)](https://rubyonrails.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.3+-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](#license)

</div>

---

## 🎬 Demo

<!--
  Add a short screen recording (10–30s) showing: opening the shelf → searching →
  opening a book → resuming reading position → deleting a book.

  GitHub renders uploaded .mp4/.mov/.gif files natively when embedded like this.
  Easiest workflow:
    1. Open an Issue on this repo (or edit this README in the GitHub web UI).
    2. Drag and drop your video/gif into the text box — GitHub uploads it and
       gives you a URL like https://github.com/user/repo/assets/12345/xxxx.mp4
    3. Paste that generated line here, replacing this comment block.

  Alternatively, host the file in a `docs/demo/` folder in this repo and reference it:
-->

[[https://github.com/assets/WhatsApp Video 2026-07-03 at 6.37.01 PM.mp4](https://github.com/Arivazha9an/e-book/blob/main/assets/WhatsApp%20Video%202026-07-03%20at%206.37.01%20PM.mp4)](https://github.com/Arivazha9an/e-book/blob/main/assets/WhatsAppVideo2026-07-03at6.37.01PM-ezgif.com-video-to-gif-converter.gif)

<!-- Or, if using a GIF instead of a video: -->
<!-- ![App demo](docs/demo/app-demo.gif) -->

---

## 📸 Screenshots

<div align="center">
<table>
  <tr>
    <td align="center">
      <img src="assets/WhatsApp Image 2026-07-03 at 7.04.42 PM-3.jpeg" width="240" alt="Wooden bookshelf library view" /><br/>
      <sub><b>Library Shelf</b></sub>
    </td>
    <td align="center">
      <img src="assets/WhatsApp Image 2026-07-03 at 7.04.43 PM-2.jpeg" width="240" alt="Search screen" /><br/>
      <sub><b>Search</b></sub>
    </td>
    <td align="center">
      <img src="assets/WhatsApp Image 2026-07-03 at 7.04.42 PM-3.jpeg" width="240" alt="PDF reader view" /><br/>
      <sub><b>Reader</b></sub>
    </td>
    <td align="center">
      <img src="assets/WhatsApp Image 2026-07-03 at 7.04.42 PM.jpeg" width="240" alt="Upload screen" /><br/>
      <sub><b>Upload</b></sub>
    </td>
    <td align="center">
      <img src="assets/WhatsApp Image 2026-07-03 at 7.04.43 PM.jpeg" width="240" alt="Book DetailScreen" /><br/>
      <sub><b>Upload</b></sub>
    </td>
  </tr>
</table>
</div>

> **To add your own screenshots:** create a `docs/screenshots/` folder in the repo root, drop your PNG/JPG files in with the names above (or update the paths), commit, and push. GitHub will render them automatically once the files exist at those paths.

---

## ✨ Key Features

- 🪵 **Realistic wooden bookshelf UI** — 3D-tilted book tiles with custom shadows (bonus requirement)
- 📖 **PDF reading with persistent progress** — resumes at the exact last-read position
- 🔍 **Debounced search** — by title and author, single API call per pause in typing
- ⬆️⬇️ **Seamless upload & download** — with client-side file-size validation
- 🛡️ **Graceful error handling** — offline states, timeouts, validation errors, empty states
- ♾️ **Infinite scroll pagination** — next page pre-fetches before the user reaches the bottom

---

## 🧱 Tech Stack

### Backend
| Component | Technology |
|---|---|
| Language / Framework | Ruby 3.2 / Rails 7.1 (API mode) |
| Database | SQLite (dev/test) |
| File Storage | Active Storage (local disk) |
| Pagination | Kaminari |
| Testing | RSpec & FactoryBot |

### Frontend
| Component | Technology |
|---|---|
| Framework | Flutter 3.19+ / Dart 3.3+ |
| State Management | flutter_bloc |
| Networking | dio |
| Dependency Injection | get_it |
| PDF Rendering | syncfusion_flutter_pdfviewer |
| File Access | file_picker & permission_handler |

---

## 🏗️ Architecture

The Flutter frontend follows **Clean Architecture** with a feature-driven folder structure to maximize testability and maintainability.

```text
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
    domain/                    # Entities, repository interface, use cases — pure Dart
    data/                      # Models (JSON), remote data source, repository impl, download service
    presentation/
      bloc/                    # library/, search/, upload/, reader/, detail/
      pages/                   # LibraryShelfPage, SearchPage, EbookDetailPage, ReaderPage, UploadPage
      widgets/                 # EbookShelfGrid, EbookCoverTile
```

**Dependency direction:** `presentation → domain ← data`. The `domain` layer is pure Dart — no Flutter, no Dio, no imports from `data` or `presentation` — which keeps BLoCs and use cases trivially unit-testable.

---

## 🚀 Getting Started

### Prerequisites
- Ruby 3.2+
- Flutter 3.19+
- Xcode / Android Studio (for running on emulators or devices)

### 1. Run the Backend (Rails)

```bash
# Install dependencies
bundle install

# Create and migrate the database
bin/rails db:create db:migrate

# (Optional) Seed demo ebooks
bin/rails db:seed

# Start the Rails server
bin/rails server
```

The API is now available at `http://localhost:3000/api/v1`.

### 2. Run the Frontend (Flutter)

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

> **Note:** On an Android emulator, the app defaults to `10.0.2.2:3000` to reach the local Rails server. On an iOS simulator, it uses `localhost:3000`. For a physical device, override with:
> ```bash
> flutter run --dart-define=API_BASE_URL=http://YOUR_IP:3000
> ```

---

## 🔌 API Reference

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/api/v1/ebooks` | Paginated list |
| `POST` | `/api/v1/ebooks` | Upload a new ebook |
| `GET` | `/api/v1/ebooks/:id` | Ebook details |
| `GET` | `/api/v1/ebooks/search?q=...` | Paginated search |
| `GET` | `/api/v1/ebooks/:id/download` | Download the file |
| `DELETE` | `/api/v1/ebooks/:id` | Delete an ebook |
| `PATCH` | `/api/v1/ebooks/:id/progress` | Update reading progress |

**Data model (`ebooks` table)** — key columns: `title`, `author`, `description`, `file_type`, `file_size`, `original_filename`, `current_page`, `total_pages`, `last_position`, `last_opened_at`.

---

## 🧪 Testing

### Backend
```bash
bundle exec rspec
```
Covers model validations/edge cases, full request specs for every endpoint (including pagination), and reading-progress persistence.

### Frontend
```bash
flutter test
```
Covers `bloc_test` state transitions for `LibraryBloc`, `SearchBloc`, and `UploadCubit`; debounce verification (rapid keystrokes → single API call); and widget tests for `EbookShelfGrid`'s infinite-scroll trigger and tap handling.

### Manual QA Checklist
- [x] Upload valid and invalid PDFs
- [x] Decline and accept storage permissions
- [x] Infinite scroll through a populated library
- [x] Search filtering by title and author
- [x] Open a book, scroll halfway, exit, reopen — resumes at the exact same position
- [x] Long-press to delete a book — removed from both UI and API

---

## 🎨 Product & UX Decisions

<details>
<summary><b>Empty library state</b></summary>
<br>
Instead of a blank screen: a friendly empty state with a book icon and the message "Your shelf is empty. Tap 'Add book' to upload your first ebook."
</details>

<details>
<summary><b>Upload failure handling</b></summary>
<br>
<code>UploadCubit</code> maps failures to the UI — validation errors (e.g. missing title) show inline on the form; network errors surface a <code>SnackBar</code> without wiping the user's entered data, so they can retry easily.
</details>

<details>
<summary><b>Oversized files</b></summary>
<br>
Checked client-side before the upload starts — files over 50MB immediately raise a <code>FileTooLargeFailure</code>, avoiding wasted bandwidth and wait time. The backend enforces the same limit via Active Storage validations as a second line of defense.
</details>

<details>
<summary><b>No search results</b></summary>
<br>
A dedicated empty state reads "No books match '[query]'", confirming the search completed rather than leaving the user guessing.
</details>

<details>
<summary><b>Loading states</b></summary>
<br>
Initial load shows a custom <code>ShelfLoadingSkeleton</code> shimmer matching the bookshelf aesthetic, rather than a generic spinner. Infinite-scroll pagination shows a small non-blocking spinner at the bottom of the list.
</details>

<details>
<summary><b>Error display strategy</b></summary>
<br>

- **Fatal** (e.g. initial load fails) → full-screen <code>ErrorView</code> with icon, friendly message, and a Retry button.
- **Non-fatal** (e.g. a delete fails on a spotty connection) → <code>SnackBar</code>, preserving the user's place on the shelf.
- **Offline** → a persistent <code>ConnectivityBanner</code> appears in real time; read-only requests auto-retry once on timeout.
</details>

<details>
<summary><b>Delete confirmation</b></summary>
<br>
Long-press on a book triggers a native <code>AlertDialog</code> — "Delete this ebook?" with a destructive-colored Delete button — before any backend request fires.
</details>

---

## ⚠️ Error Handling Strategy

Every failure is modeled as a specific `Failure` subtype rather than a generic exception:

| Failure Type | Behavior |
|---|---|
| `NoInternetFailure` | Checked *before* the request fires; surfaced via a live `ConnectivityBanner` |
| `TimeoutFailure` | Read-only requests auto-retry once before surfacing an error |
| `ValidationFailure` | 422 errors surfaced directly in the relevant UI field |
| Non-fatal errors | Shown as a `SnackBar` so the user never loses their place |

---

## 📌 Known Limitations

1. **Single-user environment** — authentication (Devise/JWT) is intentionally omitted to keep focus on core functionality; the library and progress are globally shared.
2. **EPUB rendering** — the backend fully accepts and stores EPUBs, but the reader currently uses `syncfusion_flutter_pdfviewer`, which renders PDFs only. EPUB reading would need a secondary rendering package.
3. **Cover generation** — covers are provided manually on upload, or fall back to a deterministic color-block placeholder. Automatic PDF-to-image cover extraction isn't implemented yet.

---

## 🤖 AI Tool Usage

An AI coding assistant (Antigravity/Gemini) was used as a collaborative development partner throughout this project.

**How it was used:**
- **Architecture & scaffolding** — generated boilerplate for the Flutter Clean Architecture layers (domain/data/presentation) and core Rails controllers.
- **UI implementation** — helped derive the `BoxShadow` and `Transform` matrices behind the wooden bookshelf's realistic 3D tilt effect.
- **Debugging & testing** — diagnosed a widget-test failure caused by a lingering `Future.delayed` timer in `BookLiftAnimation`, and suggested the correct `pumpAndSettle()` / `pump(Duration)` combination to flush the event loop.
- **Permissions** — assisted wiring up `permission_handler` and the corresponding Android manifest / iOS `Info.plist` entries.

**Manual review & ownership:**
- The overall architecture (Clean Architecture + BLoC), the API contract, and where/how AI assistance was applied were all decided manually — nothing was accepted without review.
- All generated state-management logic was reviewed to ensure loading, empty, and failure states were handled correctly; overly generic AI error handling was replaced with the strict `Failure`-subtype strategy described above.
- Product decisions — like turning offline states and denied permissions into friendly, actionable `SnackBar`s instead of raw exceptions — were driven manually.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

</div>
