import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/outbox.dart';
import '../models/visit.dart';
import '../models/session_record.dart';
import '../models/behavior_log.dart';
import 'local_database.dart';
import 'filemaker_service.dart';

/// Service for handling offline-first operations with outbox pattern
/// Manages queueing operations locally and syncing to FileMaker when online
class OfflineSyncService extends ChangeNotifier {
  final LocalDatabase _localDb = LocalDatabase();
  final Connectivity _connectivity = Connectivity();
  FileMakerService? _fileMakerService;
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingCount = 0;
  
  // Max retry attempts per item
  static const int maxRetries = 5;
  
  // Sync batch size (process items in batches)
  static const int batchSize = 10;

  OfflineSyncService() {
    _initialize();
  }

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;

  /// Initialize the service
  Future<void> _initialize() async {
    // Check initial connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(connectivityResult);
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        final wasOnline = _isOnline;
        _isOnline = _isConnected(result);
        
        if (!wasOnline && _isOnline) {
          // Connection restored - trigger auto-sync
          print('🌐 Connection restored, triggering auto-sync...');
          syncPendingItems();
        }
        
        notifyListeners();
      },
    );
    
    // Load initial pending count
    await _updatePendingCount();
  }

  /// Check if connectivity result indicates online status
  bool _isConnected(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }

  /// Set FileMaker service reference
  void setFileMakerService(FileMakerService fileMakerService) {
    _fileMakerService = fileMakerService;
  }

  /// Queue an operation to the outbox
  Future<int> queueOperation({
    required String entityType,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final outbox = Outbox(
      entityType: entityType,
      operation: operation,
      payload: payload,
      syncStatus: 'pending',
    );

    final id = await _localDb.addToOutbox(outbox);
    await _updatePendingCount();
    
    print('📦 Queued operation: $entityType.$operation (id: $id)');
    
    // If online, try to sync immediately
    if (_isOnline && !_isSyncing) {
      syncPendingItems();
    }
    
    return id;
  }

  /// Sync pending items to FileMaker
  Future<void> syncPendingItems({bool showProgress = true}) async {
    if (_isSyncing) {
      print('⏳ Sync already in progress, skipping...');
      return;
    }

    if (!_isOnline) {
      print('📴 Offline - cannot sync');
      return;
    }

    if (_fileMakerService == null) {
      print('⚠️ FileMakerService not set, cannot sync');
      return;
    }

    _isSyncing = true;
    if (showProgress) notifyListeners();

    try {
      // Get pending items
      final pendingItems = await _localDb.getPendingOutboxes(limit: batchSize);
      
      if (pendingItems.isEmpty) {
        // Check for failed items that can be retried
        final retryableItems = await _localDb.getRetryableOutboxes(limit: batchSize);
        if (retryableItems.isEmpty) {
          print('✅ No items to sync');
          await _updatePendingCount();
          return;
        }
        await _syncItems(retryableItems);
      } else {
        await _syncItems(pendingItems);
      }
      
      // Update pending count
      await _updatePendingCount();
      
      // Continue syncing if there are more items
      final remainingPending = await _localDb.getPendingCount();
      if (remainingPending > 0) {
        print('🔄 More items to sync ($remainingPending), continuing...');
        await Future.delayed(const Duration(milliseconds: 500));
        await syncPendingItems(showProgress: false);
      }
      
    } catch (e) {
      print('❌ Error syncing items: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Sync a list of outbox items
  Future<void> _syncItems(List<Outbox> items) async {
    for (final item in items) {
      try {
        // Mark as syncing
        await _localDb.markAsSyncing(item.id!);
        
        // Execute the operation based on entity type and operation
        await _executeOperation(item);
        
        // Mark as synced and delete
        await _localDb.markAsSynced(item.id!);
        await _localDb.deleteOutbox(item.id!);
        
        print('✅ Synced: ${item.entityType}.${item.operation} (id: ${item.id})');
        
      } catch (e) {
        print('❌ Failed to sync ${item.entityType}.${item.operation}: $e');
        
        // Increment retry count
        final newRetryCount = item.retryCount + 1;
        final errorMessage = e.toString();
        
        if (newRetryCount >= maxRetries) {
          print('⚠️ Max retries reached for item ${item.id}, marking as permanently failed');
        }
        
        // Mark as failed
        await _localDb.markAsFailed(
          item.id!,
          errorMessage,
          newRetryCount,
        );
      }
    }
  }

  /// Execute an operation from the outbox
  Future<void> _executeOperation(Outbox item) async {
    if (_fileMakerService == null) {
      throw Exception('FileMakerService not available');
    }

    switch (item.entityType) {
      case 'visit':
        await _syncVisit(item);
        break;
      case 'session_record':
        await _syncSessionRecord(item);
        break;
      case 'behavior_log':
        await _syncBehaviorLog(item);
        break;
      default:
        throw Exception('Unknown entity type: ${item.entityType}');
    }
  }

  /// Sync a visit operation
  Future<void> _syncVisit(Outbox item) async {
    if (_fileMakerService == null) return;
    
    final payload = item.payload;
    
    if (item.operation == 'create') {
      // Reconstruct Visit from payload
      final visit = Visit.fromJson(payload);
      await _fileMakerService!.createVisitWithDio(visit, skipLocation: payload['skipLocation'] == true);
    } else if (item.operation == 'update') {
      // For updates, we need visit data
      final visit = Visit.fromJson(payload);
      await _fileMakerService!.updateVisit(visit);
    } else if (item.operation == 'updateEndTs') {
      // Update visit end timestamp
      final visitId = payload['visitId'] as String;
      final endTs = DateTime.parse(payload['endTs'] as String);
      await _fileMakerService!.updateVisitEndTs(visitId, endTs);
    } else if (item.operation == 'updateNotes') {
      // Update visit notes
      final visitId = payload['visitId'] as String;
      final notes = payload['notes'] as String;
      await _fileMakerService!.updateVisitNotes(visitId, notes);
    } else if (item.operation == 'cancel') {
      // Cancel visit
      final visitId = payload['visitId'] as String;
      await _fileMakerService!.cancelVisit(visitId);
    }
  }

  /// Sync a session record operation
  Future<void> _syncSessionRecord(Outbox item) async {
    if (_fileMakerService == null) return;
    
    final payload = item.payload;
    
    if (item.operation == 'upsert' || item.operation == 'create' || item.operation == 'update') {
      // Reconstruct SessionRecord from payload
      final record = SessionRecord.fromJson(payload);
      await _fileMakerService!.upsertSessionRecord(record);
    }
  }

  /// Sync a behavior log operation
  Future<void> _syncBehaviorLog(Outbox item) async {
    if (_fileMakerService == null) return;
    
    final payload = item.payload;
    
    if (item.operation == 'create') {
      // Reconstruct BehaviorLog from payload
      final behaviorLog = BehaviorLog.fromJson(payload);
      await _fileMakerService!.createBehaviorLog(behaviorLog);
    }
  }

  /// Update pending count
  Future<void> _updatePendingCount() async {
    _pendingCount = await _localDb.getPendingCount();
    notifyListeners();
  }

  /// Get all pending items (for UI display)
  Future<List<Outbox>> getPendingItems() async {
    return await _localDb.getAllOutboxes(syncStatus: 'pending');
  }

  /// Get all failed items (for UI display)
  Future<List<Outbox>> getFailedItems() async {
    return await _localDb.getAllOutboxes(syncStatus: 'failed');
  }

  /// Clear all synced items (cleanup)
  Future<void> clearSyncedItems() async {
    final syncedItems = await _localDb.getAllOutboxes(syncStatus: 'synced');
    for (final item in syncedItems) {
      if (item.id != null) {
        await _localDb.deleteOutbox(item.id!);
      }
    }
    await _updatePendingCount();
  }

  /// Dispose resources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

