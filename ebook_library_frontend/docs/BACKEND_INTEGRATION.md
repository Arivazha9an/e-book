# Connecting the Flutter App to the Rails Backend

This app is built against the API documented in the backend repo's
`docs/API_DOCUMENTATION.md`. This doc covers the frontend-specific setup:
where the base URL lives, how each screen maps to an endpoint, and how to
point the app at a different backend (local, staging, etc.).

## 1. Base URL

Everything routes through one constant:

```dart
// lib/core/constants/api_constants.dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000',
);
```

Override it without touching code:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.23:3000
```

| Target | URL to use |
|---|---|
| Android emulator, Rails running on your machine | `http://10.0.2.2:3000` (default) |
| iOS simulator, Rails running on your machine | `http://localhost:3000` |
| Physical device, same Wi-Fi as your machine | `http://<your-machine-LAN-IP>:3000` |
| Deployed/staging backend | its real `https://...` URL |

## 2. Screen → Endpoint Map

| Screen | Endpoint(s) | Notes |
|---|---|---|
| `LibraryShelfPage` | `GET /api/v1/ebooks` | Infinite-scroll pagination; refetches page 1 on pull-to-refresh or sort change |
| `SearchPage` | `GET /api/v1/ebooks/search` | Debounced 400ms; paginated the same way as the shelf |
| `EbookDetailPage` | `GET /api/v1/ebooks/:id`, `DELETE /api/v1/ebooks/:id`, `GET /api/v1/ebooks/:id/download` | Delete asks for confirmation before calling the API |
| `UploadPage` | `POST /api/v1/ebooks` (multipart) | Reports upload progress via Dio's `onSendProgress` |
| `ReaderPage` | `PATCH /api/v1/ebooks/:id/progress` | Debounced 3s while reading; one final un-debounced call on close |

## 3. Request/Response Contract

The frontend's data models mirror the backend's JSON exactly:

- `EbookModel.fromJson` ↔ backend's `EbookSerializer#as_json`
- `PaginatedEbooksResponse.fromJson` ↔ the `{ data, meta }` envelope
- `ReadingProgressModel.fromJson` ↔ both the embedded `progress` object and
  the standalone `GET/PATCH .../progress` response shape

If the backend's JSON shape changes, these three files (in
`lib/features/ebooks/data/models/`) are the only place that needs updating —
nothing above the data layer knows about JSON keys at all.

## 4. Multipart Upload

`EbookRemoteDataSourceImpl.uploadEbook` builds the exact multipart fields the
backend expects:

```
ebook[title]         (required)
ebook[author]        (optional)
ebook[description]   (optional)
ebook[file]           (required)
ebook[cover_image]    (optional)
```

File size is checked client-side against the same 50MB limit the backend
enforces (`ApiConstants.maxUploadBytes`), so oversized files fail fast with a
friendly message instead of uploading megabytes just to get rejected.

## 5. Downloads

`GET /api/v1/ebooks/:id/download` responds with a `302` redirect to a signed
blob URL. `EbookDownloadService` uses Dio's `.download()`, which follows
redirects automatically, so the frontend just points at the `/download`
endpoint URL directly — no special redirect handling needed.

## 6. Reading Progress Contract

The frontend never needs a separate "am I resuming?" flag — it just reads
whatever the backend last saved:

```json
"progress": {
  "current_page": 57,
  "total_pages": 320,
  "last_position": 0.178,
  "percent": 17.8,
  "last_opened_at": "2026-07-01T18:40:00Z"
}
```

`current_page: 0` / `last_opened_at: null` means "never opened" — the reader
opens at page 1 in that case. Otherwise `ReaderPage` jumps straight to
`current_page` once the PDF finishes loading.

## 7. CORS

The backend's `config/initializers/cors.rb` allows all origins in
development. This matters less for a native mobile app (CORS is a browser
concept), but does matter if you ever run this as Flutter Web — in that
case, lock the Rails CORS config down to your actual web app's origin before
shipping.

## 8. Error Contract

The backend returns one of two shapes on error, and the frontend's
`DioErrorMapper` handles both:

```json
{ "error": "message" }
{ "errors": ["message one", "message two"] }
```

| Status | Frontend `Failure` |
|---|---|
| (offline, checked before request) | `NoInternetFailure` |
| timeout | `TimeoutFailure` |
| 404 | `NotFoundFailure` |
| 422 | `ValidationFailure` (carries the full `errors` array) |
| 5xx | `ServerFailure` |
| anything else | `UnknownFailure` |

## 9. Local Smoke Test

With the backend running (`bin/rails server`) and seeded
(`bin/rails db:seed`):

```bash
curl http://localhost:3000/api/v1/health
# {"status":"ok","time":"..."}
```

Then run the Flutter app pointed at the same host — the shelf should load
the seeded demo books on first launch.
