# Digital Ebook Library — Backend API Documentation

This document describes the Rails API that the Flutter app talks to. Everything
is JSON except the download endpoint (which streams the file) and file uploads
(which use `multipart/form-data`).

**Base URL (local dev):** `http://localhost:3000`
**API prefix:** `/api/v1`

---

## 0. Health Check

```
GET /api/v1/health
```

Use this on app startup to confirm the Flutter app can reach the backend.

**Response `200`**
```json
{ "status": "ok", "time": "2026-07-02T10:00:00Z" }
```

---

## 1. List Ebooks (paginated)

```
GET /api/v1/ebooks
```

### Query parameters

| Param       | Type   | Default | Notes                                                              |
|-------------|--------|---------|----------------------------------------------------------------------|
| `page`      | int    | `1`     | 1-indexed page number                                                |
| `per_page`  | int    | `20`    | Capped at `50` server-side                                           |
| `sort`      | string | `recent`| `recent` \| `oldest` \| `title` \| `author` \| `recently_read`       |
| `file_type` | string | —       | Filter by `pdf` or `epub`                                            |

### Response `200`

```json
{
  "data": [
    {
      "id": 12,
      "title": "Clean Code",
      "author": "Robert C. Martin",
      "description": null,
      "file_type": "pdf",
      "file_size": 2481234,
      "original_filename": "clean-code.pdf",
      "cover_url": "http://localhost:3000/rails/active_storage/blobs/.../cover.jpg",
      "download_url": "http://localhost:3000/api/v1/ebooks/12/download",
      "created_at": "2026-06-30T09:12:00Z",
      "updated_at": "2026-07-01T18:40:00Z",
      "progress": {
        "current_page": 57,
        "total_pages": 320,
        "last_position": 0.178,
        "percent": 17.8,
        "last_opened_at": "2026-07-01T18:40:00Z"
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total_pages": 4,
    "total_count": 73
  }
}
```

`cover_url` is `null` when no cover image was uploaded — render a placeholder
shelf-book icon in that case.

**Pagination pattern for Flutter:** keep requesting `page: current_page + 1`
while `meta.current_page < meta.total_pages`. This works well with an
`infinite_scroll_pagination`-style controller or a simple "Load more" button.

---

## 2. Search Ebooks (paginated)

```
GET /api/v1/ebooks/search
```

Same pagination/sort/file_type params as above, plus:

| Param | Type   | Required | Notes                                      |
|-------|--------|----------|---------------------------------------------|
| `q`   | string | yes      | Matches title, author, or original filename |

### Response `200`
Same envelope as List Ebooks, with `meta.query` echoing the search term. An
empty `data: []` array (not an error) is returned when nothing matches —
render your "no results" empty state for that case.

Recommend debouncing the search field ~300–400ms client-side before firing
the request.

---

## 3. Get a Single Ebook

```
GET /api/v1/ebooks/:id
```

**Response `200`** — same shape as one item in the `data` array above.
**Response `404`** — `{ "error": "Couldn't find Ebook with 'id'=999" }`

---

## 4. Upload an Ebook

```
POST /api/v1/ebooks
Content-Type: multipart/form-data
```

### Form fields

| Field                 | Required | Notes                                   |
|------------------------|----------|------------------------------------------|
| `ebook[title]`          | yes      | Max 255 chars                            |
| `ebook[author]`         | no       |                                            |
| `ebook[description]`    | no       |                                            |
| `ebook[file]`           | yes      | PDF or EPUB, max 50 MB                   |
| `ebook[cover_image]`    | no       | Any image type                           |

### Flutter example (using `http` + `MultipartRequest`)

```dart
final uri = Uri.parse('$baseUrl/api/v1/ebooks');
final request = http.MultipartRequest('POST', uri)
  ..fields['ebook[title]'] = title
  ..fields['ebook[author]'] = author
  ..files.add(await http.MultipartFile.fromPath('ebook[file]', filePath));

final streamed = await request.send();
final response = await http.Response.fromStream(streamed);
```

### Response `201` — the created ebook (same shape as GET :id)

### Response `422` — validation failure

```json
{ "errors": ["Title can't be blank", "File must be a PDF or EPUB file"] }
```

Common validation errors to handle in the UI:
- Missing title
- Missing file
- Unsupported file type (must be PDF/EPUB)
- File too large (> 50 MB)

---

## 5. Download an Ebook

```
GET /api/v1/ebooks/:id/download
```

Returns a `302` redirect to a signed, time-limited file URL
(`Content-Disposition: attachment`). Most HTTP clients (including Dart's
`http` package with `followRedirects: true`, the default) will follow this
automatically — just point your download manager at this URL.

**Response `404`** if the ebook or its file doesn't exist.

---

## 6. Delete an Ebook

```
DELETE /api/v1/ebooks/:id
```

**Response `204`** — no body, deletion succeeded.
**Response `404`** — ebook didn't exist.

Show a confirmation dialog in the UI before calling this — the backend does
not ask for confirmation itself.

---

## 7. Reading Progress ("continue where they left off")

This is how the app remembers the exact page/scroll position a user was at,
so opening a book from the shelf resumes instead of restarting at page 1.

### 7a. Get current progress

```
GET /api/v1/ebooks/:id/progress
```

**Response `200`**
```json
{
  "ebook_id": 12,
  "current_page": 57,
  "total_pages": 320,
  "last_position": 0.178,
  "percent": 17.8,
  "last_opened_at": "2026-07-01T18:40:00Z"
}
```

A never-opened book returns `current_page: 0`, `last_opened_at: null`,
`percent: 0.0` — treat that as "start from the beginning."

### 7b. Update progress

```
PATCH /api/v1/ebooks/:id/progress
Content-Type: application/json
```

**Body** (all fields optional — send whatever your reader widget tracks):
```json
{
  "current_page": 58,
  "total_pages": 320,
  "last_position": 0.181
}
```

- `current_page` / `total_pages`: use these for paginated PDF readers.
- `last_position`: a `0.0`–`1.0` fraction; use this for continuous-scroll
  EPUB readers, or as a fallback when page counts aren't known yet.
- Fields you omit keep their previously saved value — you don't need to
  resend everything on every call.

**Recommended call pattern:** debounce/throttle this (e.g. every 3–5 seconds
of reading, or on page turn, or on app pause/dispose) rather than calling it
on every single scroll event.

**Response `200`** — same shape as 7a, reflecting the new values.
**Response `422`** — e.g. `{ "errors": ["Current page must be greater than or equal to 0"] }`

### Suggested Flutter flow

1. When a book is tapped from the shelf, call `GET .../progress` (or just
   read the `progress` object already included in the list/show response)
   and open the reader at `current_page` (or scroll to `last_position`).
2. While reading, periodically call `PATCH .../progress` with the latest
   position.
3. On leaving the reader screen, fire one final `PATCH` to make sure the
   last position is saved even if the debounce timer hasn't fired yet.

---

## Error Format

All error responses use one of these shapes:

```json
{ "error": "message" }
```
```json
{ "errors": ["message one", "message two"] }
```

| Status | Meaning                                   |
|--------|---------------------------------------------|
| 400    | Malformed request (e.g. missing required param wrapper) |
| 404    | Record not found                            |
| 422    | Validation failed                           |

---

## CORS

CORS is enabled for `/api/*` and `/rails/active_storage/*` (needed so cover
image URLs load directly in `Image.network(...)`). During development all
origins are allowed; lock this down to your actual app origin(s) in
`config/initializers/cors.rb` before shipping.
