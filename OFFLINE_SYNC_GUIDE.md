# Offline-First Architecture Guide

This app implements an **offline-first architecture** using the **Outbox Pattern**. All operations work locally first, then sync to FileMaker when connectivity is available.

## Architecture Overview

### Components

1. **LocalDatabase** (`lib/services/local_database.dart`)
   - SQLite database for local storage
   - Manages `outboxes` table for pending operations

2. **OfflineSyncService** (`lib/services/offline_sync_service.dart`)
   - Handles queueing operations
   - Monitors connectivity
   - Syncs pending items to FileMaker
   - Retry logic (max 5 attempts)

3. **Outbox Model** (`lib/models/outbox.dart`)
   - Represents pending operations
   - Stores entity type, operation, payload, sync status

4. **SyncBanner Widget** (`lib/widgets/sync_banner.dart`)
   - Shows pending items count
   - Manual sync button
   - Connection status indicator

## How It Works

### 1. Queueing Operations

When you perform an operation (create visit, save session record, etc.), it:

1. **Saves to local SQLite first** (immediate)
2. **Queues to outbox** (pending sync)
3. **Attempts sync if online** (automatic)
4. **Stays queued if offline** (syncs later)

### 2. Syncing Process

When online:
- Auto-syncs when connection restored
- Processes items in batches (10 at a time)
- Retries failed items (max 5 attempts)
- Updates sync status (pending → syncing → synced/failed)

### 3. Retry Logic

- Failed items increment `retryCount`
- Max 5 retry attempts
- After max retries, item marked as permanently failed
- Can manually retry failed items

## Usage Examples

### Example 1: Creating a Visit (Offline-First)

**Before (Direct FileMaker call):**
```dart
final visit = Visit(...);
final createdVisit = await fileMakerService.createVisitWithDio(visit);
```

**After (Offline-First):**
```dart
import 'package:provider/provider.dart';
import '../services/offline_sync_service.dart';

// Get services
final offlineSync = Provider.of<OfflineSyncService>(context, listen: false);
final fileMakerService = Provider.of<FileMakerService>(context, listen: false);

// Queue operation
await offlineSync.queueOperation(
  entityType: 'visit',
  operation: 'create',
  payload: visit.toJson()..['skipLocation'] = false,
);

// If online, sync immediately (optional)
if (offlineSync.isOnline) {
  await offlineSync.syncPendingItems();
}
```

### Example 2: Saving Session Record (Offline-First)

```dart
final offlineSync = Provider.of<OfflineSyncService>(context, listen: false);

// Queue the session record
await offlineSync.queueOperation(
  entityType: 'session_record',
  operation: 'upsert',
  payload: sessionRecord.toJson(),
);
```

### Example 3: Logging Behavior (Offline-First)

```dart
final offlineSync = Provider.of<OfflineSyncService>(context, listen: false);

await offlineSync.queueOperation(
  entityType: 'behavior_log',
  operation: 'create',
  payload: behaviorLog.toJson(),
);
```

### Example 4: Updating Visit End Time

```dart
final offlineSync = Provider.of<OfflineSyncService>(context, listen: false);

await offlineSync.queueOperation(
  entityType: 'visit',
  operation: 'updateEndTs',
  payload: {
    'visitId': visitId,
    'endTs': DateTime.now().toIso8601String(),
  },
);
```

## Adding Sync Banner to UI

Add the `SyncBanner` widget to any screen:

```dart
import '../widgets/sync_banner.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(...),
    body: Column(
      children: [
        const SyncBanner(), // Add this
        // Rest of your content
      ],
    ),
  );
}
```

The banner automatically shows:
- Pending items count
- Sync status (syncing/offline)
- Manual "Sync Now" button (when online)

## Integration Points

### Supported Operations

1. **Visit Operations:**
   - `create` - Create new visit
   - `update` - Update visit
   - `updateEndTs` - Update end timestamp
   - `updateNotes` - Update visit notes
   - `cancel` - Cancel visit

2. **Session Record Operations:**
   - `upsert` - Create or update session record
   - `create` - Create session record
   - `update` - Update session record

3. **Behavior Log Operations:**
   - `create` - Create behavior log

## Monitoring Sync Status

```dart
final offlineSync = Provider.of<OfflineSyncService>(context, listen: true);

// Check if syncing
if (offlineSync.isSyncing) {
  // Show loading indicator
}

// Check pending count
final pendingCount = offlineSync.pendingCount;

// Check online status
if (offlineSync.isOnline) {
  // Online - can sync
} else {
  // Offline - operations queued
}
```

## Manual Sync

```dart
final offlineSync = Provider.of<OfflineSyncService>(context, listen: false);

// Trigger manual sync
await offlineSync.syncPendingItems();
```

## Getting Pending Items

```dart
final offlineSync = Provider.of<OfflineSyncService>(context, listen: false);

// Get all pending items
final pendingItems = await offlineSync.getPendingItems();

// Get failed items
final failedItems = await offlineSync.getFailedItems();
```

## Best Practices

1. **Always queue operations first** - Don't call FileMakerService directly
2. **Use SyncBanner** - Show users sync status
3. **Handle errors gracefully** - Failed items are retried automatically
4. **Monitor sync status** - Use `isSyncing` and `pendingCount` for UI updates
5. **Test offline scenarios** - Verify operations work when offline

## Migration Path

To migrate existing code:

1. Replace direct `FileMakerService` calls with `queueOperation`
2. Add `SyncBanner` to main screens
3. Update UI to show sync status
4. Test offline scenarios

## Troubleshooting

### Items Not Syncing

1. Check connectivity: `offlineSync.isOnline`
2. Check pending count: `offlineSync.pendingCount`
3. Check sync status: `offlineSync.isSyncing`
4. Manually trigger sync: `await offlineSync.syncPendingItems()`

### Failed Items

- Items with `retryCount >= 5` are permanently failed
- Check error messages in outbox
- May need to fix payload format or FileMaker API issues

### Database Issues

- SQLite database: `datasheets.db` in app data directory
- Can clear database: Close and reopen app (will recreate)
- Check logs for SQLite errors

