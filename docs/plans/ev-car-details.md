# EV Car Details Plan

## Goal

Replace the current third tab (Maintenance) with a new `Car details` tab that acts as a car-centric hub, and add two new entities:

- `Document` (PNG, JPG, JPEG, PDF, HEIC, etc.)
- `Idea` (Title, URL, Description)

Implementation must follow the document handling approach used in Journey Wallet and CreativityHub (document type detection, picker, preview, metadata model, and developer document browser).

## Scope

### In scope

- New `Car details` tab UI (third tab)
- Car selector at top (disabled when only one car)
- Preview blocks with last 3 records:
  - Maintenance
  - Documents
  - Ideas
- Navigation from each block to full list screen
- Persistent circular floating create button in Car flow
- Root `Car details` FAB opens a modal object selector (what to create)
- Child screens opened from Car flow keep the same FAB and use context-specific create action
- New DB entities and repositories for `documents` and `ideas`
- Document file storage and preview flow similar to Journey/Creativity
- Developer mode tools:
  - button to view all app documents in storage browser
- Backup/export/import updates for new entities

### Out of scope (this iteration)

- Replacing existing maintenance business logic
- Changing existing expense/car schema
- Reworking Share Extension behavior for documents/ideas
- Cloud sync changes

## UI Visualization

### Tab bar change

Current:

```text
[Stats] [Expenses] [Maintenance] [Settings]
```

Planned:

```text
[Stats] [Expenses] [Car] [Settings]
```

The maintenance pending badge moves to the new `Car` tab.

### Car details main screen

```text
+--------------------------------------------------------------+
|                    Navigation: Car details                  |
+--------------------------------------------------------------+
| Car                                                         |
| [ Tesla Model 3                    v ]                      |
| (disabled if only one car exists)                          |
+--------------------------------------------------------------+
| Maintenance                                      [See all >] |
| ------------------------------------------------------------ |
| 1) Brake fluid change               Due in 4 days           |
| 2) Tire rotation                    320 km left             |
| 3) Cabin filter                     Overdue                 |
| (tap block -> existing Maintenance view)                    |
+--------------------------------------------------------------+
| Documents                                        [See all >] |
| ------------------------------------------------------------ |
| 1) Insurance_2026.pdf               PDF  420 KB             |
| 2) service_receipt.jpg              JPEG 1.2 MB             |
| 3) wheel_specs.png                  PNG  300 KB             |
| (tap block -> Documents view)                               |
+--------------------------------------------------------------+
| Ideas                                            [See all >] |
| ------------------------------------------------------------ |
| 1) Wheel setup idea                  reddit.com/...          |
|    Better winter setup...                                  |
| 2) Tint workshop                     instagram.com/...       |
| 3) Mobile charger option             tesla.com/...          |
| (tap block -> Ideas view)                                   |
+--------------------------------------------------------------+
|                                                      (+) FAB |
+--------------------------------------------------------------+
```

### Floating create button behavior

```text
Root Car details screen:

  Tap (+) -> show modal dialog with create options:
    - New Maintenance record
    - New Document
    - New Idea
    - (future) any additional car-scoped object

Screen opened from Car details flow:

  Maintenance list   -> tap (+) opens Add Maintenance directly
  Documents list     -> tap (+) opens Add Document directly
  Ideas list         -> tap (+) opens Add Idea directly

Rules:
  - FAB is visible across all screens pushed from Car details flow.
  - FAB action is route-aware (current screen type determines create action).
  - On root screen only, FAB opens object chooser modal.
```

### Car details empty states

```text
No cars:
- Show message: "Add your first car in Settings to start tracking"
- Hide or disable content blocks

No records in a block:
- Show compact empty placeholder inside block
- Keep block tappable to open full list and add first item
```

### Documents list flow

```text
Car details -> Documents (full list) -> + Add
  -> Import from Files / Photos / Camera
  -> Enter optional custom title
  -> Save file to app group storage
  -> Persist metadata in DB
  -> Open preview (PDFKit/Image viewer)
```

### Ideas list flow

```text
Car details -> Ideas (full list) -> + Add/Edit
  Fields:
  - Title (required)
  - URL (optional)
  - Description (optional)
```

## Data Model

## 1) Document

`documents` table (car scoped)

- `id` INTEGER PRIMARY KEY AUTOINCREMENT
- `car_id` INTEGER NOT NULL
- `custom_title` TEXT NULL
- `file_name` TEXT NOT NULL
- `file_path` TEXT NULL
- `file_type` TEXT NOT NULL
- `file_size` INTEGER NOT NULL
- `created_at` DATETIME NOT NULL
- `updated_at` DATETIME NOT NULL

Indexes:

- `idx_documents_car_id`
- `idx_documents_created_at`

Model fields in app layer:

- `id`, `carId`, `customTitle`, `fileName`, `filePath`, `fileType`, `size`, `createdAt`, `updatedAt`

Notes:

- Keep metadata parity with Journey/Creativity behavior.
- Physical file location remains file system (App Group), not BLOB in SQLite.

## 2) Idea

`ideas` table (car scoped)

- `id` INTEGER PRIMARY KEY AUTOINCREMENT
- `car_id` INTEGER NOT NULL
- `title` TEXT NOT NULL
- `url` TEXT NULL
- `description` TEXT NULL
- `created_at` DATETIME NOT NULL
- `updated_at` DATETIME NOT NULL

Indexes:

- `idx_ideas_car_id`
- `idx_ideas_updated_at`

## Architecture

### New feature module

- `EVChargingTracker/EVChargingTracker/CarDetails/CarDetailsView.swift`
- `EVChargingTracker/EVChargingTracker/CarDetails/CarDetailsViewModel.swift`
- `EVChargingTracker/EVChargingTracker/CarDetails/CarDetailsFlowContainerView.swift` (NavigationStack + persistent FAB overlay)
- Optional small reusable rows/cards for section previews

### New business logic

- `BusinessLogic/Models/Document.swift`
- `BusinessLogic/Models/Idea.swift`
- `BusinessLogic/Database/DocumentsRepository.swift`
- `BusinessLogic/Database/IdeasRepository.swift`
- `BusinessLogic/Services/DocumentService.swift`

### New migrations

- `Migration_*_CreateDocumentsTable.swift`
- `Migration_*_CreateIdeasTable.swift`

### Developer mode tools

- `EVChargingTracker/EVChargingTracker/Developer/DocumentStorageService.swift`
- `EVChargingTracker/EVChargingTracker/Developer/DocumentStorageBrowserView.swift`
- Add button in `UserSettingsView` developer section:
  - `View app documents`

## Navigation Plan

1. `MainTabView` third tab points to `CarDetailsView`.
2. `CarDetailsView` section taps navigate to:
   - existing `PlanedMaintenanceView`
   - new `DocumentsListView`
   - new `IdeasListView`
3. Avoid nested navigation issues:
   - if needed, extract maintenance content from internal `NavigationView` so it can be pushed cleanly from Car details.
4. Keep navigation under a Car flow container that owns a persistent FAB.
5. Implement route-aware create dispatcher:
   - root Car details route -> present create-object modal
   - maintenance route -> open add maintenance screen
   - documents route -> open document picker/add flow
   - ideas route -> open add idea form

## Migration and Data Safety

1. Additive migrations only (new tables/indexes).
2. No destructive changes to existing tables (`cars`, `charging_sessions`, `planned_maintenance`, etc.).
3. Keep migration execution at first DB access (already true in current app via `DatabaseManager` init).
4. Existing user data must remain intact after update.
5. On car deletion:
   - delete related document/idea records,
   - delete car document files from storage.

## Document Handling Parity (Journey/Creativity)

Implement the same practical behavior:

- file type detection by extension/UTType
- import from Files/Photos/Camera
- optional custom title
- metadata persistence in DB
- file operations through `DocumentService`
- PDF preview (PDFKit)
- image preview with zoom support
- share/open-in from preview
- file size formatting and type badge in rows

## Backup/Export/Import Updates

Update export/import payload and backup flow:

- include `ideas` in JSON export/import
- include `documents` metadata in JSON export/import
- include restorable document file references and corresponding files (not metadata-only restore)
- restore document files before creating document DB rows
- fail import on any document/idea insert failure (no silent partial success)
- clear document files from storage during full wipe/import replacement flows

### Backup safety requirements (must-have)

- A restored document must be previewable/openable after import.
- Import must not report success when document/idea insertion fails.
- Data wipe must remove both DB rows and corresponding physical files.

## Implementation Phases

1. Tab and navigation update
2. Car flow container with persistent circular FAB + route-aware create dispatcher
3. Car details screen with static sections
4. Documents data layer (model + migration + repository + service)
5. Documents UI (list, add, preview, delete, rename)
6. Ideas data layer (model + migration + repository)
7. Ideas UI (list, add/edit, delete)
8. Wire previews (last 3) into Car details
9. Developer document browser + settings button
10. Backup/export/import integration for ideas/documents metadata and files
11. Backup/import hardening (strict error handling + file cleanup)
12. Localization + tests + final QA

## Testing Plan

### Migration safety

- Upgrade from existing DB with real data: no loss in cars/expenses/maintenance
- New tables created correctly on first launch

### Car details behavior

- Car selector enabled only when car count > 1
- Correct preview data per selected car
- Section taps navigate to expected full views
- FAB is shown on Car details and on screens opened from Car details
- FAB on root opens create-object modal
- FAB on child screens opens the correct create flow directly

### Documents

- Import from Files/Photos/Camera
- Supported type detection and preview
- Metadata correctness (`customTitle`, `filePath`, `size`, `createdAt`, `updatedAt`)
- Delete updates DB and file system
- Export/import round-trip keeps documents openable (preview works after restore)

### Ideas

- CRUD operations with validation (title required)
- URL optional, description optional
- Last-3 preview ordering by newest

### Developer mode

- `View app documents` button visible only in developer mode
- Browser opens and displays storage tree correctly

### Regression

- Existing maintenance flows still work when opened from Car details
- App builds Debug/Release
- Full tests pass (`./run_tests.sh`)
- Import does not silently succeed on partial document/idea failures
- Wipe/import cycle does not leave orphaned files in document storage

## Acceptance Criteria

- Third tab is `Car details` and maintenance is reachable from its block
- Car details shows 3 blocks with last 3 records each
- Car flow has a persistent circular FAB across pushed screens
- Root FAB opens create-object modal; child routes open route-specific create screen
- Documents entity and full flow are working and metadata complete
- Ideas entity and CRUD are working
- Developer mode includes document browser action
- Existing user data is preserved during migration

## Planned File Touch List

- `EVChargingTracker/EVChargingTracker/MainTabView.swift`
- `EVChargingTracker/EVChargingTracker/MainTabViewModel.swift`
- `EVChargingTracker/EVChargingTracker/CarDetails/*`
- `EVChargingTracker/EVChargingTracker/CarDetails/CarDetailsFlowContainerView.swift` (new)
- `EVChargingTracker/EVChargingTracker/PlanedMaintenance/*` (navigation embedding adjustments only)
- `EVChargingTracker/EVChargingTracker/Documents/*` (new)
- `EVChargingTracker/EVChargingTracker/Ideas/*` (new)
- `EVChargingTracker/EVChargingTracker/Developer/*` (new)
- `EVChargingTracker/EVChargingTracker/UserSettings/UserSettingsView.swift`
- `BusinessLogic/Models/Document.swift` (new)
- `BusinessLogic/Models/Idea.swift` (new)
- `BusinessLogic/Database/DocumentsRepository.swift` (new)
- `BusinessLogic/Database/IdeasRepository.swift` (new)
- `BusinessLogic/Database/DatabaseManager.swift`
- `BusinessLogic/Database/Migrations/*` (new migration files)
- `BusinessLogic/Services/DocumentService.swift` (new)
- `BusinessLogic/Helpers/AppGroupContainer.swift` (documents path extension)
- `BusinessLogic/Models/ExportModels.swift`
- `BusinessLogic/Services/BackupService.swift`
- `EVChargingTracker/*.lproj/Localizable.strings`
