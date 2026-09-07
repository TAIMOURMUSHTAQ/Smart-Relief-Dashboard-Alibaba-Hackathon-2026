# Relief Dashboard - QA Report

## Testing methodology

This machine has no Android emulator or physical device reliably available for full on-device testing (see "Environment note" below), so every feature was verified through automated Flutter tests that exercise the real app code, real widget tree, and real Firestore query/write logic, backed by fake in-memory Firebase services (`fake_cloud_firestore` and `firebase_auth_mocks`) instead of a live network. This gives fast, deterministic, repeatable runs of the exact same screens, providers, and business logic that ship in the APK, without needing a device.

What this approach does verify:
- Screen navigation and state transitions (signup, login, sign out, tab switching)
- Form validation and submission logic
- Firestore reads/writes/queries exactly as the app performs them (collection names, field names, transactions)
- Cross-session data routing (a volunteer's request appearing in an admin's view via the shared backend)
- Rendering correctness (layout overflow, error states)

What this approach cannot verify (needs a real device, and is unaffected by the code changes made this session):
- Camera photo capture (`image_picker`)
- Real GPS location retrieval (`geolocator`)
- Real Firebase network latency/behavior and the actual deployed Firestore security rules on your live project
- OpenStreetMap tile rendering over a real network connection

### Environment note

An Android emulator was set up and booted successfully, but the host machine only has ~7.4 GB of RAM with under 0.4 GB free once the emulator, IDE, and browser were running simultaneously. Under that memory pressure the emulator's internal package-manager service crashed intermittently during app installs (different transient errors each time: "Broken pipe", "device offline", "Can't find service: package"), which is a host resource limitation, not an app defect. Given that, testing was switched to the fake-Firebase widget/unit test approach described above, at your direction.

## Test suite

14 automated tests across 4 files, run 3 times each (42 total runs):

| File | Covers |
|---|---|
| `test/signup_and_home_test.dart` | Sign up as admin/volunteer, correct landing screen, sign out |
| `test/seed_and_auth_repair_test.dart` | Demo data seeding, and the profile-repair fix for the original "profile not found" bootstrap bug |
| `test/request_routing_and_allocation_test.dart` | Request submission (existing inventory item and custom item), cross-session routing from volunteer to admin, stock allocation math, over-allocation rejection |
| `test/dashboard_and_map_test.dart` | Dashboard summary counts, map screen rendering |

## Results by iteration

| Iteration | Result |
|---|---|
| 1 (first pass) | 8 failures found, all fixed (see below), then re-run to 14/14 passing |
| 2 | 14/14 passing |
| 3 | 14/14 passing |

## Bugs found and fixed this session

1. **Dropdown overflow (real UI bug, found by the test suite).** The item-selection dropdown on the "New Request" screen, and four other dropdowns app-wide (signup role, inventory category, inventory warehouse, allocation warehouse), could overflow horizontally and throw a rendering error when their selected text was long (e.g. "Other (custom item)"). Fixed by adding `isExpanded: true` to all five `DropdownButtonFormField` widgets, which is the standard Flutter fix and lets long text truncate with an ellipsis instead of overflowing.

2. **`FirestoreService` eagerly touched `FirebaseStorage.instance` in its constructor**, which requires a real Firebase app to exist even for code paths that never upload a photo. Fixed by making Storage access lazy (only initialized the first time a photo upload is actually attempted). This was blocking the test harness and was also unnecessary work on every app screen that doesn't touch photos.

3. Carried over from earlier in this session (already in the current APK, re-confirmed here by the automated tests): the Firestore collection name mismatch between the app code (`requests`) and the security rules the README instructed you to paste (`reliefRequests`), the signup screen's stuck-loading/navigation race, the missing "sign out" escape hatch on profile errors, and the "no seeded accounts" chicken-and-egg bug, are all covered by `seed_and_auth_repair_test.dart` and `signup_and_home_test.dart` and pass consistently across all 3 iterations.

## What you still need to verify manually on your phone

- Photo attachment on a real camera
- "Use my location" GPS button
- That your live Firebase project actually has the corrected `firestore.rules` and the composite index published (these are config on Firebase's servers, not something a local test can check)
- General feel/performance on your actual device

## Final APK

Rebuilt after all fixes above, from a clean `flutter analyze` (no issues) and a fully passing test suite:

```
C:\Users\taimo\Desktop\AliBaba Hackathon\dashboard\build\app\outputs\flutter-apk\app-release.apk
```
