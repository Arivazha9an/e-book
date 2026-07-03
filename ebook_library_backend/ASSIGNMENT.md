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
