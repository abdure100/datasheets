import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/offline_sync_service.dart';

/// Banner widget that shows pending sync items and allows manual sync
class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineSyncService>(
      builder: (context, syncService, child) {
        // Only show banner if there are pending items
        if (syncService.pendingCount == 0 && !syncService.isSyncing) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: syncService.isOnline
              ? (syncService.isSyncing ? Colors.blue : Colors.orange)
              : Colors.grey,
          child: Row(
            children: [
              Icon(
                syncService.isSyncing
                    ? Icons.sync
                    : syncService.isOnline
                        ? Icons.cloud_upload
                        : Icons.cloud_off,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  syncService.isSyncing
                      ? 'Syncing ${syncService.pendingCount} item(s)...'
                      : syncService.isOnline
                          ? '${syncService.pendingCount} item(s) pending sync'
                          : 'Offline - ${syncService.pendingCount} item(s) queued',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (syncService.isOnline && !syncService.isSyncing)
                TextButton(
                  onPressed: () => syncService.syncPendingItems(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: const Text(
                    'Sync Now',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (syncService.isSyncing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

