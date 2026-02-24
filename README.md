# Flutter Camera Sync

A Flutter app that captures photos, queues them in batches, and uploads them to [imgBB](https://imgbb.com/) with a resilient sync engine that works offline and retries on failure.

---

## 1. Business Requirements

### 1.1 Core Features

- **Camera capture**: Full-screen camera with pinch-to-zoom, tap-to-focus, and capture button. Photos are stored locally and grouped into batches.
- **Batch-based upload queue**: Each capture session uses a batch. Images are added to the current batch and queued for upload with status: `pending` → `uploading` → `uploaded` (or kept `pending` on failure for retry).
- **Image upload to imgBB**: Upload uses the [imgBB API](https://api.imgbb.com/) via **Dio** with **multipart/form-data**. A shared Dio client is used so other APIs can be added later.
- **Pending screen**: Users see all pending batches with small image previews. Refreshing or opening the tab reloads data from the local database. Failed or network-blocked uploads stay **pending** and are retried.

### 1.2 Non-Functional Requirements

- **Offline-first**: Capture and queue work without network. Upload runs when the app is online (immediately after capture when possible, or in the background).
- **Resilient sync**: If upload fails (network, API error, or any exception), the image is set back to **pending** so it is retried on the next sync (hybrid or background), without losing data.
- **Background upload**: A periodic background task (Workmanager, ~15 min, when connected) uploads pending images so uploads continue even when the app is closed.

---

## 2. Technical Implementation

### 2.1 Architecture Overview

The app follows **Clean Architecture** with feature-based modules:

- **Core**: Shared infrastructure (database, network, storage, services, result/use-case base).
- **Features**:
  - **Camera**: Capture, preview, zoom, focus; depends on camera domain + sync domain for batching.
  - **Sync**: Batches, upload queue, sync to imgBB; depends on camera entities (e.g. `UploadStatus`, `CapturedImage`).

Each feature is split into:

- **Domain**: Entities, repository interfaces (abstract classes), use cases. No Flutter or external packages (except equatable/core types).
- **Data**: Repository implementations, data sources, mappers (DB ↔ domain).
- **Presentation**: BLoC (events/states), screens, UI.

### 2.2 State Management: BLoC

- **CameraBloc**  
  - **Events**: `CameraStarted`, `CameraStopped`, `CameraCapturePressed`, `CameraZoomChanged`, `CameraFocusRequested`.  
  - **States**: `CameraInitial`, `CameraLoading`, `CameraFailureState`, `CameraReady`.  
  - Handles camera lifecycle, capture flow, create batch / add image to batch, and triggers a **fire-and-forget** sync after each successful capture (hybrid upload).

- **UploadQueueBloc**  
  - **Events**: `UploadQueueStarted`, `UploadQueueRefreshed`.  
  - **States**: `UploadQueueInitial`, `UploadQueueLoading`, `UploadQueueEmpty`, `UploadQueueFailureState`, `UploadQueueLoaded(batches)`.  
  - Loads pending batches with images via `GetPendingBatchesWithImages` for the Pending screen. Refreshed when the user opens the Pending tab.

### 2.3 Clean Architecture Layers

| Layer        | Camera feature                          | Sync feature                                      |
|-------------|-----------------------------------------|---------------------------------------------------|
| **Domain**  | Entities: `CapturedImage`, `CaptureBatch`, `CameraDevice`, `FocusPoint`, `UploadStatus`. Repositories: `CameraRepository`. Use cases: `GetAvailableCameras`, `InitializeCamera`, `DisposeCamera`, `CaptureImage`, `ChangeZoom`, `SetFocusPoint`. | Entities: `BatchWithImages`. Repositories: `BatchRepository`, `SyncRepository`. Use cases: `CreateBatch`, `AddImageToBatch`, `GetPendingBatches`, `GetPendingBatchesWithImages`, `SyncPendingBatches`. |
| **Data**    | `CameraDataSource`, `CameraRepositoryImpl`.          | `BatchRepositoryImpl`, `SyncRepositoryImpl`; mappers for batch/image. |
| **Presentation** | `CameraBloc`, `CameraPreviewScreen`.        | `UploadQueueBloc`, `PendingUploadsScreen`.        |

Dependencies point inward: presentation → domain ← data. Use cases depend only on repository abstractions.

### 2.4 Local Database (Drift)

- **Location**: `lib/core/db/app_database.dart` (schema), `app_database.g.dart` (generated).
- **Tables**:
  - **Batches**: `id`, `createdAt`, `label`, `status` (pending | uploading | uploaded | failed).
  - **Images**: `id`, `filePath`, `capturedAt`, `batchId` (FK), `thumbnailPath`, `width`, `height`, `deviceName`, `uploadStatus` (pending | uploading | uploaded | failed).
- **Usage**: Batch and sync repositories read/write batches and images; sync updates `uploadStatus` and batch `status` after upload success or failure (failure → set image back to `pending`).

### 2.5 Networking and Upload

- **DioClient** (`lib/core/network/dio_client.dart`): Reusable Dio instance (optional `baseUrl`, timeouts). Exposes `dio` for use by any API layer.
- **ImgBB API** (`lib/core/network/imgbb/`):
  - `ImgBbApi`: Takes `Dio` and API key; `uploadImage(filePath)` sends multipart/form-data to `https://api.imgbb.com/1/upload?key=...`.
  - `ImgBbUploadResponse` / `ImgBbImageData`: Response models (e.g. `url`, `displayUrl`).
  - `imgbb_config.dart`: API key via `kImgBbApiKey` (override with `--dart-define=IMGBB_API_KEY=...`).
- **SyncRepositoryImpl**: Loads images with `uploadStatus == pending`, marks as uploading, calls `ImgBbApi.uploadImage`, then marks uploaded or (on any failure) **pending** again for retry.

### 2.6 Background Sync (Workmanager)

- **Registration**: In `main.dart`, after `WidgetsFlutterBinding.ensureInitialized()`, `Workmanager().initialize(callbackDispatcher)` and `registerPeriodicTask('sync-pending-task', syncTaskName, constraints: NetworkType.connected)`.
- **Interval**: Default periodic interval is 15 minutes (Workmanager minimum). Task runs only when the device is considered connected.
- **Worker** (`lib/background/sync_worker.dart`): Entry point `callbackDispatcher` → `executeTask`. Checks connectivity via `ConnectivityService`; if offline, returns without changing data. If online, builds `AppDatabase`, `DioClient`, `ImgBbApi`, `SyncRepositoryImpl`, `SyncPendingBatches` and runs `syncPending()`. Individual failures are reflected in DB status (e.g. pending for retry); the task still reports success so Workmanager continues to schedule runs.

### 2.7 Resilient Sync Engine

- **Hybrid upload**: Right after a successful capture and add-to-batch, the app triggers `SyncPendingBatches` in a **fire-and-forget** way (no await). If the network is available, pending images (including the one just captured) upload quickly; if not, they remain pending.
- **Failure handling**: On **any** upload failure (network, API error, or other exception), the image is set back to **pending** (not failed), so:
  - Next time the user opens the Pending tab, they see the batch and images; refreshing loads from DB.
  - Next sync (same session, or background run) will retry those pending images.
- **No data loss**: Images stay in the local DB until uploaded; status transitions are pending ↔ uploading → uploaded, with failures falling back to pending.

---

## 3. Technical Diagram

### 3.1 High-Level Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              FLUTTER APP                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────┐     ┌─────────────────────┐                        │
│  │   Camera Tab        │     │   Pending Tab       │                        │
│  │   CameraPreview     │     │   PendingUploads    │                        │
│  │   Screen            │     │   Screen             │                        │
│  └──────────┬──────────┘     └──────────┬──────────┘                        │
│             │                            │                                    │
│             ▼                            ▼                                    │
│  ┌─────────────────────┐     ┌─────────────────────┐                        │
│  │   CameraBloc         │     │   UploadQueueBloc   │                        │
│  │   (capture, zoom,   │     │   (load batches     │                        │
│  │    focus, batch)    │     │    with images)     │                        │
│  └──────────┬──────────┘     └──────────┬──────────┘                        │
│             │                            │                                    │
│             │  fire-and-forget           │                                    │
│             │  sync after capture        │                                    │
│             ▼                            ▼                                    │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                    DOMAIN USE CASES                                    │  │
│  │  CreateBatch | AddImageToBatch | SyncPendingBatches |                 │  │
│  │  GetPendingBatchesWithImages | CaptureImage | InitializeCamera | ...  │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│             │                                    │                           │
│             ▼                                    ▼                           │
│  ┌─────────────────────┐     ┌─────────────────────────────────────────┐   │
│  │   CameraRepository  │     │   BatchRepository | SyncRepository       │   │
│  │   (impl)            │     │   (impl)                                  │   │
│  └──────────┬──────────┘     └────────────────────┬────────────────────┘   │
│             │                                      │                         │
│             ▼                                      ▼                         │
│  ┌─────────────────────┐     ┌─────────────────────────────────────────┐   │
│  │   CameraDataSource   │     │   AppDatabase (Drift)  │  ImgBbApi (Dio) │   │
│  │   (camera plugin)    │     │   Batches + Images      │  multipart      │   │
│  └─────────────────────┘     └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
             │
             │  Workmanager (periodic, ~15 min, when connected)
             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  BACKGROUND ISOLATE (sync_worker)                                            │
│  ConnectivityService → SyncRepositoryImpl → SyncPendingBatches → ImgBB     │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Sync and Upload Status Flow

```
                    ┌─────────────┐
                    │   pending   │◄───────────────────┐
                    └──────┬──────┘                    │
                           │ sync picks up             │ any failure
                           ▼                           │ (network / API / other)
                    ┌─────────────┐                    │
                    │  uploading  │                    │
                    └──────┬──────┘                    │
                           │                           │
              success      │                           │
                           ▼                           │
                    ┌─────────────┐                    │
                    │  uploaded   │                    │
                    └─────────────┘                    │
                                                       │
                    (image stays pending for retry) ────┘
```

### 3.3 Project Structure (lib)

```
lib/
├── main.dart                    # DI, Workmanager registration, runApp
├── root_shell.dart              # Tab shell: Camera | Pending, refresh on Pending
├── background/
│   └── sync_worker.dart         # Workmanager entry, background sync
├── core/
│   ├── db/
│   │   ├── app_database.dart    # Drift schema (Batches, Images)
│   │   └── app_database.g.dart  # Generated
│   ├── error/
│   │   └── failure.dart         # Failure types (Camera, Storage, Network, …)
│   ├── network/
│   │   ├── dio_client.dart      # Reusable Dio client
│   │   └── imgbb/
│   │       ├── imgbb_api.dart   # Multipart upload to imgBB
│   │       ├── imgbb_config.dart
│   │       └── imgbb_models.dart
│   ├── result/
│   │   └── result.dart          # Result<T> (success | failure)
│   ├── services/
│   │   ├── connectivity_service.dart
│   │   └── permission_service.dart
│   ├── storage/
│   │   └── local_file_storage.dart
│   └── usecase/
│       └── use_case.dart        # UseCase<T, P> base
└── features/
    ├── camera/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   └── camera_data_source.dart
    │   │   └── repositories/
    │   │       └── camera_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   ├── capture_batch.dart
    │   │   │   ├── captured_image.dart
    │   │   │   ├── camera_device.dart
    │   │   │   ├── focus_point.dart
    │   │   │   └── upload_status.dart
    │   │   ├── repositories/
    │   │   │   └── camera_repository.dart
    │   │   └── usecases/
    │   │       └── (initialize, capture, zoom, focus, dispose, …)
    │   └── presentation/
    │       ├── bloc/
    │       │   ├── camera_bloc.dart
    │       │   ├── camera_event.dart
    │       │   └── camera_state.dart
    │       └── pages/
    │           └── camera_preview_screen.dart
    └── sync/
        ├── data/
        │   ├── mappers/
        │   │   ├── batch_mappers.dart
        │   │   └── image_mappers.dart
        │   └── repositories/
        │       ├── batch_repository_impl.dart
        │       └── sync_repository_impl.dart
        ├── domain/
        │   ├── entities/
        │   │   └── batch_with_images.dart
        │   ├── repositories/
        │   │   ├── batch_repository.dart
        │   │   └── sync_repository.dart
        │   └── usecases/
        │       └── (create_batch, add_image, get_pending_*, sync_pending_batches)
        └── presentation/
            ├── bloc/
            │   ├── upload_queue_bloc.dart
            │   ├── upload_queue_event.dart
            │   └── upload_queue_state.dart
            └── pages/
                └── pending_uploads_screen.dart
```

---

## 4. Other Important Points

### 4.1 Configuration

- **imgBB API key**: Default is in `lib/core/network/imgbb/imgbb_config.dart`. For production, override with:
  ```bash
  flutter run --dart-define=IMGBB_API_KEY=your_key
  ```

### 4.2 Running the App

```bash
flutter pub get
# Optional: generate Drift code if you change schema
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### 4.3 Debug Logging

- **ImgBbApi**: `dev.log` with `name: 'ImgBbApi'` for start, success, and failure (file not found, empty response, non-200).
- **SyncRepositoryImpl**: `dev.log` with `name: 'SyncRepositoryImpl'` for each image upload attempt, success, DioException, and unexpected errors. Filter by these names in DevTools or the IDE console.

### 4.4 Key Dependencies

| Package           | Purpose                    |
|------------------|----------------------------|
| flutter_bloc     | State management           |
| camera           | Capture and preview        |
| drift            | Local SQLite (batches, images) |
| dio              | HTTP; used by ImgBbApi     |
| workmanager      | Background periodic sync   |
| permission_handler | Camera permission        |
| connectivity_plus | Connectivity check in worker |
| path_provider    | App documents dir for DB and files |

### 4.5 Testing and Extending

- **Unit tests**: Domain use cases and repositories can be tested with mocked repositories. BLoCs can be tested with mocked use cases.
- **Adding another API**: Reuse `DioClient.dio` (or a new Dio instance) and implement a new API class (e.g. `OtherApi(dio)`); inject it where needed without changing the sync flow.
- **Schema changes**: Edit `app_database.dart`, bump `schemaVersion`, add a migration in `AppDatabase`, then run `dart run build_runner build --delete-conflicting-outputs`.

---

This README reflects the full project so that anyone can understand the business goals, technical design, and where to look in the codebase for camera, sync, local DB, and background upload behavior.
