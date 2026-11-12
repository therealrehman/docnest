# DocNest

Your Personal Document Life Manager. Every important document. One secure home.

Current state: **Phase 1 complete (as far as possible without a device). Phase 2 complete in code except crop. Phase 3 complete in code (database, favorites, archive, rename, folders, tags). Phase 4 part 2 in code (search, filters, rule-based folder suggestions, personal filing rules). OCR is not done.** Nothing here has been compiled or run yet. See Status.

This is one merged project. It was assembled from the nine phase snapshots (Phase 1 to Phase 4 part 2). Every file comes from the newest snapshot that contains it, and the Phase 4 part 2 snapshot already had all 61 files.

## Build on GitHub (Gradle)

The workflow is `.github/workflows/android-build.yml`. It runs on pushes to `main` or `master`, on pull requests, and on **Actions > Android build > Run workflow**.

- **analyze-and-test** job: `flutter pub get`, Drift code generation, `flutter analyze`, `flutter test`.
- **build-apk** job: Java 17 and Gradle caching, then `flutter build apk --debug` and `--release`. Flutter runs Gradle inside `android/` for both. The job does not wait for the test job.
- Both jobs run `bash tool/setup_android.sh` first. The repo has no `android/` folder, so that script runs `flutter create` once per run to make the Gradle project, then adds the camera permission to `AndroidManifest.xml`.

To get the APK: open the run in the Actions tab and download the **docnest-apk** artifact (`app-debug.apk` and `app-release.apk`).

Notes:
- **The first run is the first real compile.** Nothing in this project has been built yet, so expect errors in the first log. Send the failing log lines and they can be fixed.
- The release APK is signed with the debug key. Add a real keystore before a store upload. `key.properties` and `*.jks` are already in `.gitignore`.
- Flutter is pinned to `3.27.4` in the workflow (`FLUTTER_VERSION`). Change it there, not in each step.

## What is in the project

- `lib/app/`: app root, GoRouter routes, bottom-navigation shell, motion tokens, theme
- `lib/core/`: default categories, onboarding flag and theme choice storage (`shared_preferences`), Drift database
- `lib/shared/`: logo, primary gradient button, empty state, entrance fade, stat card, formatters, one-field prompt dialog
- `lib/features/splash/`, `onboarding/`: splash and three onboarding pages with Canvas illustrations
- `lib/features/home/`: dashboard with real document count, Import and Scan actions, recent documents
- `lib/features/documents/` (Phase 2 to 4):
  - `data/`: document model, private file store (copies files into app storage), personal filing rule model, `document_store.dart` (all database access for documents, folders, tags and rules)
  - `application/`: controller (import, delete, save scanned PDF), the shared import flow, search and filter logic
  - `application/category_rules.dart`: the suggestion engine (keywords, pattern, personal rules, confidence)
  - `application/filing_rules_controller.dart`: saves, turns on and off, and deletes personal rules
  - `presentation/`: document row, preview (images zoom, PDFs scroll), details screen, folder and tag editor
- `lib/features/folders/` (Phase 3 part 2):
  - `data/folder_record.dart`: folder model (built-in or user)
  - `application/folders_controller.dart`: create, rename, delete folders
  - `presentation/folders_screen.dart`, `folder_detail_screen.dart`, `folder_tile.dart`: folder list, one folder's documents, rows
- `lib/features/scan/` (Phase 2):
  - `data/scan_page.dart`: one captured page (photo path, rotation)
  - `application/scan_session.dart`: pages of the current scan, in memory (add, retake, rotate, delete, reorder, clear)
  - `application/pdf_builder.dart`: builds the A4 PDF in a background isolate
  - `presentation/scan_screen.dart`: camera preview, capture, Done, retake mode
  - `presentation/scan_review.dart`: page list, rotate, retake, delete, reorder, file name, save as PDF
- `lib/features/reminders/`: tab (not built yet)
- `lib/features/settings/`: tab. Settings > Appearance (Light / Dark / System) works and is saved. Settings > Organize > Filing rules opens the rules list.
- `test/`: suggestion engine tests, document filter tests, folder id tests, scan session tests, one widget smoke test (not run yet)

## Phase 4 part 2: suggestions and personal rules

Works (in code, not yet run):
- **Whole-word matching.** Keywords match whole words, and a plural "s" is allowed. "lease" no longer matches "please" or "release", and "deed" no longer matches "needed". "bills" still matches Bills.
- **Scoring.** Each folder earns points from signals, and each signal counts once per folder:
  - file name keyword: 30
  - OCR text keyword: 40 (the engine accepts OCR text, but no OCR text is produced yet)
  - a CNIC-style number in the name, such as `35202-1234567-1`: 20 (dashes are required, so 13-digit timestamps do not match)
  - a personal rule: 10
- **What is shown.** High confidence (one folder clearly leads, at 30 or more with no close rival): a "Suggested: <folder>" chip, as before. Medium confidence (several folders are possible, or only a weaker signal matched): a "Possible folders" row with up to three chips. No match: nothing is shown. The weights and thresholds are first guesses, not calibrated.
- **Nothing moves by itself.** A folder changes only when the user taps a chip or picks a folder.
- **Personal rules.** When the user moves a document that had a suggestion into a folder the suggestion did not offer, DocNest asks "Always suggest <folder>?". The dialog pre-fills the longest useful word from the file name (numbers, months, file types and filler words are skipped). The user can edit it. Saving creates a rule. Later file names with that word get that folder as a suggestion.
- **Filing rules screen.** Settings > Organize > Filing rules lists the rules. Each rule has an on/off switch and a delete button, and delete asks first. Deleting a folder also deletes the rules that point to it.
- **Search still works** the same way: name, tags, folder name, with the All / Favorites / Archived views and the type and tag filters.

Not done yet:
- **OCR.** No text is read from scans or images. Search still cannot find words that appear only inside a file, and the OCR weight (40) is not used in the app yet. This needs an on-device text recognition plugin that has been checked first. Urdu OCR has not been tested and is not promised.
- **Content-based rules.** Rules and built-in keywords look only at the file name. Once OCR exists, the same engine can use the text.
- **Built-in keywords are not overridden.** A personal rule adds 10 points. For example, a rule "bill" → Finance does not remove the built-in Bills suggestion for "bill.pdf", because Bills keeps 30 points and Finance gets 10. If this feels wrong on a real phone, change the weights at the top of `category_rules.dart`.
- **Pro gating.** Custom rules are a Pro feature in the blueprint. They are not gated yet; that comes with the Pro work in Phase 8.
- **Pattern rules are few.** The only identifier pattern is a CNIC-style number. More are added only after testing on real files.
- **Rules are not exported in backups.** Backup comes in Phase 7.

## Phase 4 part 1 (still in code)

- Search (Documents tab): matches the document name, its tags and its folder name, ignoring case. It combines with the All / Favorites / Archived views, a type filter (All types, PDF, Images) and a tag filter (tap a tag chip; tap again to clear it).
- Documents tab filters and the search box share one query, so the tag filter and the type filter work together.

## Phase 2: what works and what does not

Works (in code, not yet run):
- Import PDF, JPG, JPEG, PNG and WEBP from the system picker, several files at once. Other types are skipped with a message.
- Scan: take photos with the back camera, as many pages as needed. Review the pages: rotate 90° per tap, retake one page, delete a page, drag to reorder, discard all. Give the file a name and save. Every page becomes one A4 page in a single PDF, which appears in the documents list.
- Files are copied into the app's private folder. Details are saved in a local SQLite database (`docnest.sqlite`, Drift). Data from the Phase 2 `index.json` is moved in once, and the old file is renamed to `index.json.migrated`.
- Documents list (newest first), empty and error states.
- Preview: images with pinch zoom, PDFs with page scroll and zoom.
- Details screen with name, type, size and date. Delete with confirmation.
- Favorite, archive and rename from the details screen. Documents tab filters: All (hides archived), Favorites, Archived. The home count and recent list also hide archived documents.
- Folders: the default categories are built-in folders. Home shows each one with its document count, and tapping it opens its documents. The Folders screen (folder icon on the Documents tab) lists all folders with counts. You can create, rename and delete your own folders. Deleting a folder keeps its documents; they become unfiled. Built-in folders cannot be renamed or deleted.
- Move a document to a folder (or out of any folder) from the details screen.
- Tags: add and remove tags on the details screen. Tags are lowercase and up to 24 characters.
- Duplicate check: each imported file gets a SHA-256 hash. A file whose content is already in DocNest is not copied again. The import message says how many were skipped. Scanned PDFs are not checked. Documents saved before version 3 get their hash on the first open after the update.
- Share: the Share button on the details screen opens the system share sheet with a copy named like the document. Saving from there (Files, Drive) is how a copy leaves DocNest. Saving straight to Downloads is not built yet.

Not done yet:
- **Scan quality help:** no automatic edge detection, crop, perspective correction, brightness or filters. Pages are saved as the camera took them, with only the user's rotation applied.
- Crop for scanned pages (Phase 2 leftover). A bigger UI step, planned on its own.
- Save straight to Downloads without the share sheet, and a prompt that lets you import a duplicate anyway.
- **Encryption.** Files and the database are not encrypted yet. Phase 6 adds AES-GCM with Android Keystore. Do not describe the storage as protected until then.

## Codegen step (required)

The Drift tables in `lib/core/database/app_database.dart` need generated code. After `flutter pub get`, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Until this runs, `flutter analyze` reports missing `app_database.g.dart` and `_$AppDatabase` errors. That is expected. The generated file is not in the zip. **This version adds a table, so run it again after pulling this version.**

- The database is `documents/docnest.sqlite` inside the app's documents folder.
- The Phase 2 JSON migration runs once, on the first open. It uses insert-or-ignore, so a retry is safe. If it fails, `index.json` is kept and the Documents tab shows an error.
- The schema is now version 4 (folders, tags, folder column, content hash, filing rules). Older versions upgrade in place: the folder column and built-in folders come with version 2, the hash column with version 3, and the filing rules table with version 4. Hashes for old documents are filled in on the first open.
- Not tested: migration with real data on a device, folder delete and tag add/remove on a phone, and the `sqlite3_flutter_libs` setup on Android.

## Known limits in the scan flow

- **Rotation direction:** check on a device that a page rotated in review turns the same way in the saved PDF. The preview and the PDF use the same clockwise steps, but this has not been tested.
- **Photos wait in the temporary cache** until the PDF is saved or the scan is discarded. If the OS clears the cache in the middle of a scan, saving shows an error and the pages need to be taken again.
- **Scan pages stay in memory.** Closing the app during a scan loses the pages that were not saved.
- **Camera lifecycle is basic.** The camera stays open under the review screen, and returning from the background is not handled yet. If the preview freezes after the phone sleeps, leave and reopen the scan screen.
- **No blur or darkness check** on captured photos.
- **Quality:** JPEG quality 85, longest side 1800 px. Tune in `pdf_builder.dart` after testing on a real page.

## Android setup for the camera

The `android/` folder is not in the repo. `tool/setup_android.sh` creates it and adds this line above `<application` in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

Without it, the camera screen shows the permission error message. The script skips this step if the line is already there.

## Still open

- **Inter font is not bundled.** Add the `.ttf` files under `assets/fonts/`, declare family `Inter` in a `fonts:` block under `flutter:` in `pubspec.yaml`, then set `fontFamily: 'Inter'` in `lib/app/theme/app_theme.dart`.
- **Phase 0 (inspecting the existing GitHub repo) is not done.** This project does not know what the repo already contains.
- **Onboarding illustrations** are simple Canvas drawings. Final artwork comes in the polish phase.

## Dependencies

Phase 1 and 2:
- `flutter_riverpod` ^2.5.1, `go_router` ^14.2.0, `shared_preferences` ^2.2.3, `path_provider` ^2.1.2

Phase 2:
- `file_picker` ^8.0.0: system file picker
- `pdfx` ^2.6.0: PDF rendering
- `camera` ^0.11.0: back camera preview and capture
- `image` ^4.2.0: decode, orientation fix, rotate, resize and JPEG encode of scan pages
- `pdf` ^3.11.0: builds the scan PDF

Phase 2 leftovers:
- `crypto` ^3.0.3: SHA-256 for duplicate checks
- `share_plus` ^10.0.0: system share sheet (`Share.shareXFiles`, `XFile`). Check the API on the first `flutter analyze`. Newer share_plus versions may deprecate `Share`.

Phase 3 part 1:
- `drift` ^2.20.0 and `sqlite3_flutter_libs` ^0.5.24: local database
- `drift_dev` ^2.20.0 and `build_runner` ^2.4.13 (dev only): code generation

Phase 4 part 2 adds no new packages.

These versions were chosen from memory and have not been resolved or tested here. If `flutter pub get` reports a conflict, adjust the version and tell me the error. The `camera`, `image`, `pdf` and `drift` calls are unverified until the first `flutter analyze`.

## Setup

Requires Flutter 3.27 or newer (uses `Color.withValues` and `PopScope.onPopInvokedWithResult`).

This project contains Dart code, `pubspec.yaml` and tests only. It does not include the `android/` folder. Generate it once in the project root:

```bash
bash tool/setup_android.sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

`tool/setup_android.sh` runs `flutter create` for the `android/` folder and adds the camera permission. The same script runs in GitHub Actions (see Build on GitHub).

Notes:

- `flutter create` does not overwrite existing files by default, but check `git status` after running it.
- The `com.docnest` org is a placeholder. Confirm the final package name in Phase 0 before the first store upload.
- File picking, camera capture and PDF preview need a real device or emulator to check.

## Status

- Not run in this environment: `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build`. Flutter and Dart were not installed here, and the package server (pub.dev) was blocked.
- Checked here without Dart: the matching logic was re-implemented in Python and gives the same results as every expectation in `test/category_rules_test.dart`. Brackets, strings and imports were checked in all 57 Dart files. This is not a compile. Syntax and type errors are still possible until `flutter analyze` runs.
- Not tested on a phone or emulator. The scan flow in particular has not been tried with a real camera.
- Do not treat this as a verified build. Run the commands above and report the output.
