# Digital Ebook Library Application

This repository contains the complete implementation of the Digital Ebook Library assignment, featuring a Ruby on Rails backend API and a Flutter cross-platform frontend.

The application allows users to upload, manage, search, read, download, and delete ebooks. It features a custom "wooden bookshelf" UI to provide a premium, realistic library experience, alongside offline support, reading progress tracking, and robust error handling.

## Project Overview

- **Backend**: Ruby on Rails (API-only) providing robust endpoints, pagination, file storage via Active Storage, and reading progress tracking.
- **Frontend**: Flutter utilizing Clean Architecture and BLoC state management for a highly responsive, easily testable user interface.
- **Key Features**: 
  - Realistic wooden bookshelf UI (bonus requirement)
  - PDF reading with persistent "last read" position tracking
  - Debounced search functionality (by title, author)
  - Seamless file upload and download capabilities
  - Graceful error handling (offline states, server errors, empty states)

## Tech Stack

### Backend
- **Ruby 3.2 / Rails 7.1** (API mode)
- **SQLite** (Development/Test)
- **Active Storage** (Local disk) for ebook files and covers
- **Kaminari** (Pagination)
- **RSpec & FactoryBot** (Testing)

### Frontend
- **Flutter 3.19+ / Dart 3.3+**
- **flutter_bloc** (State Management)
- **dio** (Networking)
- **get_it** (Dependency Injection)
- **syncfusion_flutter_pdfviewer** (PDF Rendering)
- **file_picker & permission_handler** (File access)

---

## Flutter Project Structure (Clean Architecture)

The Flutter frontend strictly adheres to Clean Architecture and feature-driven folders to ensure high testability and maintainability.

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
    domain/                    # Entities, repository interface, use cases — pure Dart, no Flutter/Dio imports
    data/                      # Models (JSON), remote data source, repository impl, download service
    presentation/
      bloc/                    # library/, search/, upload/, reader/, detail/
      pages/                   # LibraryShelfPage, SearchPage, EbookDetailPage, ReaderPage, UploadPage
      widgets/                 # EbookShelfGrid, EbookCoverTile
```

**Dependency Direction:** `presentation` depends on `domain`; `data` implements `domain`'s repository interface. The `domain` layer never imports Flutter, Dio, or anything from `data`/`presentation` — it's plain Dart. This makes the BLoCs and use cases extremely straightforward to unit test.

---

## Setup Instructions

### Prerequisites
- Ruby 3.2+
- Flutter 3.19+
- Xcode / Android Studio (for running the Flutter app on emulators/devices)

### 1. How to run Backend (Rails)

Open a terminal in the backend directory:

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
The API will be available at `http://localhost:3000/api/v1`.

### 2. How to run Flutter App

Open a new terminal in the frontend directory:

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```
*Note: If running on an Android emulator, the app defaults to connecting to `10.0.2.2:3000` to reach the local Rails server. For iOS simulators, it uses `localhost:3000`. You can override this using `--dart-define=API_BASE_URL=http://YOUR_IP:3000` if testing on a physical device.*

---

## Testing

### Backend Tests
Run the RSpec test suite to verify models, validations, and API endpoints:
```bash
bundle exec rspec
```

### Frontend Tests
Run the Flutter test suite to verify BLoC logic, UI rendering, and widget interactions:
```bash
flutter test
```

### Manual Testing Summary
The following core flows have been manually verified:
- [x] **Upload**: Selecting a PDF/EPUB file correctly uploads, saves metadata, and updates the shelf. (Fails gracefully if permission is denied).
- [x] **Library UI**: Books are displayed on a wooden shelf. Empty states are handled gracefully.
- [x] **Search**: Typing in the search bar debounces the query and accurately filters books by title/author.
- [x] **Reading**: Tapping a book opens the PDF viewer. Scrolling pages automatically syncs the reading progress to the backend. Closing and reopening the book resumes from the exact last position.
- [x] **Download**: Triggering a download saves the file locally and opens it natively.
- [x] **Deletion**: Long-pressing a book prompts a confirmation dialog, successfully deletes the record from the backend, and visually removes it from the shelf.

---

## API Overview

| Method | Path                              | Purpose                        |
|--------|-------------------------------------|---------------------------------|
| GET    | `/api/v1/ebooks`                    | Paginated list                  |
| POST   | `/api/v1/ebooks`                    | Upload a new ebook              |
| GET    | `/api/v1/ebooks/:id`                | Ebook details                   |
| GET    | `/api/v1/ebooks/search?q=...`       | Paginated search                |
| GET    | `/api/v1/ebooks/:id/download`       | Download the file               |
| DELETE | `/api/v1/ebooks/:id`                | Delete an ebook                 |
| PATCH  | `/api/v1/ebooks/:id/progress`       | Update reading progress         |

---

## Technical & Architectural Notes

### 1. Error Handling Strategy
Every possible failure is modeled as a specific `Failure` subtype rather than a generic exception:
- **`NoInternetFailure`**: Device is offline (checked *before* the request fires; live `ConnectivityBanner`).
- **`TimeoutFailure`**: Handled seamlessly; read-only requests auto-retry once on a timeout before surfacing an error to the user.
- **`ValidationFailure`**: Surfaces 422 errors directly in the UI.
- All non-fatal errors (e.g., a delete failing while the list is still showing) surface as a `SnackBar` so the user doesn't lose their place.

### 2. Pagination & Infinite Scroll
`EbookShelfGrid` drives pagination purely from scroll position: a `ScrollController` listener fires an `onLoadMore` event once the user scrolls within 600px of the bottom. This ensures the next page is already in flight before they reach the end—creating a seamless, pause-free scroll experience.

### 3. Reading Progress & State Sync
- **Backend**: Each ebook stores `current_page`, `total_pages`, `last_position`, and `last_opened_at`.
- **Frontend**: `ReaderCubit` debounces page-change events (3s) before calling `PATCH .../progress`. This ensures quick page scrolling doesn't spam the API. A final un-debounced save is fired when the reader is closed.

### 4. Active Storage Approach (Backend)
Files (the ebook and an optional cover image) are handled via **Rails Active Storage** with the `local` (disk) service. This keeps the assignment runnable without AWS/S3 dependencies out-of-the-box, but seamlessly supports cloud transition by simply updating `config/storage.yml`.

### 5. Data Model (`ebooks` table)
Key columns include: `title`, `author`, `description`, `file_type`, `file_size`, `original_filename`, `current_page`, `total_pages`, `last_position`, and `last_opened_at`.

---

## Known Limitations

1. **Single-User Environment**: Authentication (e.g., Devise/JWT) is currently omitted to keep the focus on core functionality. Progress and libraries are globally shared.
2. **EPUB Support**: While the backend fully accepts and stores EPUBs, the frontend reading experience currently leverages `syncfusion_flutter_pdfviewer`, which strictly renders PDFs. EPUB reading would require integrating a secondary rendering package.
3. **Cover Generation**: Ebook covers are provided manually on upload or fall back to a dynamic, deterministic color-block placeholder. Automatic PDF-to-image cover extraction is not yet implemented on the backend.

---

## AI Tools Used and How They Were Used

Throughout this assignment, I utilized an **AI Coding Assistant (Antigravity/Gemini)** as a collaborative development partner to accelerate boilerplate generation, refine UI/UX, and troubleshoot complex test environments. 

**How the AI was used:**
- **Architecture & Scaffolding**: I prompted the AI to help scaffold the Flutter Clean Architecture layers (Domain, Data, Presentation) and generate standard boilerplate for BLoCs and Cubits, which saved significant manual typing.
- **UI Implementation**: I used the AI to help execute the "wooden bookshelf" bonus requirement. I described the desired aesthetic, and the AI helped generate the complex Flutter `BoxShadow` and `Transform` matrices required to give the books a realistic, 3D tilted appearance.
- **Debugging & Testing**: When writing Flutter widget tests, I encountered an issue where `await tester.pump()` was insufficient for allowing asynchronous animations (`BookLiftAnimation`) to complete, causing test failures. The AI helped identify the lingering timer (from `Future.delayed`) and suggested the correct combination of `pumpAndSettle()` and `pump(Duration)` to cleanly flush the event loop.
- **Permissions**: I directed the AI to add the `permission_handler` and update the Android Manifest and iOS Info.plist to ensure file picking worked securely across modern OS versions.

**Manual Review & Ownership:**
- I did not blindly copy code. I dictated the overarching architecture (Clean Architecture + BLoC), defined the API contract, and explicitly decided *where* and *how* the AI should assist.
- I manually reviewed all generated state management logic to ensure it handled loading, empty, and failure states gracefully, adjusting the AI's output when its error handling was too generic.
- I took ownership of the product thinking, ensuring that edge cases (like offline states or denied permissions) resulted in friendly, actionable SnackBars rather than raw exceptions.


# Assignment Submission & Product Decisions

This document outlines how the Digital Ebook Library application directly addresses the expectations, edge cases, and product thinking criteria outlined in the assignment brief.

---

## 5. AI Tool Usage Expectation

**Which AI tools you used:**
I utilized Antigravity/Gemini as a collaborative AI coding assistant.

**How you used them & which parts were AI-assisted:**
- **Architecture & Scaffolding**: I prompted the AI to generate the boilerplate for the Flutter Clean Architecture (Domain, Data, Presentation layers) and the core Rails controllers.
- **UI Execution**: I used the AI to help implement the math and rendering logic for the bonus "wooden bookshelf" UI, specifically generating the complex `BoxShadow` and `Transform` matrices required to give the ebook tiles a realistic 3D tilt.
- **Permissions**: I guided the AI to implement `permission_handler` logic to intercept file picker requests and manage Android/iOS manifest permissions safely.

**Manual Review, Debugging, & Corrections:**
- I did not blindly accept code. I defined the API contract and the overarching BLoC architecture upfront.
- **Testing Corrections**: During frontend widget testing, the AI initially wrote a test using `tester.pump()` which failed because of lingering `Future.delayed` timers in the `BookLiftAnimation`. I reviewed this and guided the AI to properly flush the event loop using `tester.pump(Duration)` and `pumpAndSettle()`.
- **Error Handling Ownership**: The AI's initial error handling was often a generic `try/catch`. I manually enforced a strict layered strategy mapping raw exceptions to strongly-typed `Failure` classes (e.g., `TimeoutFailure`, `NoInternetFailure`) to ensure user-friendly UI responses.

---

## 6. Product Thinking & UX Decisions

**What happens when the library is empty?**
Instead of a blank screen, the user is presented with a friendly empty state featuring a book icon and clear instructions: "Your shelf is empty. Tap 'Add book' to upload your first ebook."

**What happens when upload fails?**
The `UploadCubit` catches the failure and maps it to the UI. If it's a validation error (like a missing title), it displays inline on the form. If it's a network error, a `SnackBar` alerts the user without destroying their entered form data, allowing them to retry easily.

**What happens when the ebook file is too large?**
This is handled *client-side* first. The app checks if the file exceeds 50MB before attempting the upload. It instantly throws a `FileTooLargeFailure` and alerts the user, preventing wasted data bandwidth and long waiting times. The backend also enforces this via Active Storage validations.

**What happens when search has no results?**
A dedicated empty state appears stating "No books match '[query]'", ensuring the user knows their search completed successfully but yielded no matches.

**What should the user see while data is loading?**
For the initial load, the app displays a custom `ShelfLoadingSkeleton` (a shimmer effect matching the bookshelf aesthetic) rather than a generic spinner, making the app feel native and responsive. For infinite scroll pagination, a non-blocking circular spinner appears at the bottom of the list.

**How should errors be displayed?**
- **Fatal errors** (e.g., initial load fails) take over the screen with a centralized `ErrorView` featuring an icon, friendly message, and a "Retry" button.
- **Non-fatal errors** (e.g., an ebook deletion fails over a spotty connection) use a `SnackBar`. This ensures the user doesn't lose their place on the shelf.
- **Offline status**: A persistent `ConnectivityBanner` appears in real-time when the internet drops, informing the user *before* they tap an action. Read-only requests automatically retry once on timeout.

**How should delete confirmation work?**
Users trigger deletion via a long-press on a book. Before any backend request fires, a native `AlertDialog` asks "Delete this ebook?" with a distinct, destructive-colored "Delete" button. This prevents accidental data loss.

**How does the app remain simple and easy to use?**
The interface avoids deep navigation trees. The primary view is the wooden bookshelf. A sticky bottom-anchored Floating Action Button serves as the single point of entry for uploads. The search bar is cleanly integrated into the SliverAppBar and hides when scrolling to maximize screen space for the books.

---

## 7. Testing Summary

**Backend Testing (RSpec):**
- Validations and edge cases on the `Ebook` model.
- Full request specs for API endpoints (`GET /ebooks`, `POST /ebooks`, `DELETE`, etc.), including pagination parameters.
- Reading progress state persistence.

**Frontend Testing (Flutter):**
- `bloc_test` for state transitions in `LibraryBloc`, `SearchBloc`, and `UploadCubit`.
- Debounce verification ensuring rapid keystrokes only trigger one search API call.
- Widget tests for `EbookShelfGrid` validating that the infinite-scroll trigger (`onLoadMore`) fires correctly based on scroll pixel position, and that tapping a `RealisticBookTile` registers correctly.

**Manual Testing Checklist Completed:**
- [x] Uploading valid and invalid PDFs.
- [x] Declining and accepting storage permissions.
- [x] Infinite scrolling down a populated library.
- [x] Search filtering by title and author.
- [x] Opening a book, scrolling halfway, exiting, and ensuring it reopens at the exact same position.
- [x] Long-pressing to delete a book and verifying its removal from the UI and API.
