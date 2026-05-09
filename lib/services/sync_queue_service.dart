import 'package:hive/hive.dart';
import 'package:k_tower/model/hive.dart';
import 'package:k_tower/services/entry_sync_service.dart';

class QueueProcessResult {
  final int syncedCount;
  final int pendingCount;

  const QueueProcessResult({
    required this.syncedCount,
    required this.pendingCount,
  });
}

class SyncQueueService {
  SyncQueueService._();

  static const String queueBoxName = 'sync_queue';
  static const String _saveOperation = 'save';
  static const String _deleteOperation = 'delete';

  static Future<void> queueSave({
    required dynamic localKey,
    required EntryModel entry,
  }) async {
    final queueBox = await _openQueueBox();

    await _removeMatchingOperations(
      queueBox,
      localKey: localKey,
      supabaseId: entry.supabaseId,
    );

    await queueBox.add({
      'type': _saveOperation,
      'localKey': localKey,
      'supabaseId': entry.supabaseId,
      'entry': _serializeEntry(entry),
      'queuedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> queueDelete({
    required dynamic localKey,
    required int? supabaseId,
  }) async {
    final queueBox = await _openQueueBox();

    await _removeMatchingOperations(
      queueBox,
      localKey: localKey,
      supabaseId: supabaseId,
    );

    if (supabaseId == null) {
      return;
    }

    await queueBox.add({
      'type': _deleteOperation,
      'localKey': localKey,
      'supabaseId': supabaseId,
      'queuedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> clearPendingFor({
    dynamic localKey,
    int? supabaseId,
  }) async {
    final queueBox = await _openQueueBox();
    await _removeMatchingOperations(
      queueBox,
      localKey: localKey,
      supabaseId: supabaseId,
    );
  }

  static Future<QueueProcessResult> processQueue() async {
    final queueBox = await _openQueueBox();
    final entriesBox = await Hive.openBox<EntryModel>(
      EntrySyncService.entriesBoxName,
    );
    var syncedCount = 0;

    final queueSnapshot = queueBox.toMap();
    for (final queueKey in queueSnapshot.keys.toList()) {
      final rawItem = queueSnapshot[queueKey];
      if (rawItem is! Map) {
        await queueBox.delete(queueKey);
        continue;
      }

      final item = Map<String, dynamic>.from(rawItem);
      final type = item['type'] as String?;

      try {
        if (type == _saveOperation) {
          final localKey = item['localKey'];
          final entryPayload = item['entry'];
          if (entryPayload is! Map) {
            await queueBox.delete(queueKey);
            continue;
          }

          final entry = _deserializeEntry(Map<String, dynamic>.from(entryPayload));
          final syncedEntry = await EntrySyncService.saveEntry(entry);

          if (localKey != null && entriesBox.containsKey(localKey)) {
            final localEntry = entriesBox.get(localKey);
            if (localEntry != null) {
              await entriesBox.put(
                localKey,
                localEntry.copyWith(supabaseId: syncedEntry.supabaseId),
              );
            }
          }

          await queueBox.delete(queueKey);
          syncedCount++;
          continue;
        }

        if (type == _deleteOperation) {
          await EntrySyncService.deleteEntry(item['supabaseId'] as int?);
          await queueBox.delete(queueKey);
          syncedCount++;
          continue;
        }

        await queueBox.delete(queueKey);
      } catch (_) {
        break;
      }
    }

    return QueueProcessResult(
      syncedCount: syncedCount,
      pendingCount: queueBox.length,
    );
  }

  static Future<Box<dynamic>> _openQueueBox() {
    return Hive.openBox<dynamic>(queueBoxName);
  }

  static Future<Set<dynamic>> getPendingSaveLocalKeys() async {
    final queueBox = await _openQueueBox();
    final pendingKeys = <dynamic>{};

    for (final rawItem in queueBox.values) {
      if (rawItem is! Map) {
        continue;
      }

      final item = Map<String, dynamic>.from(rawItem);
      if (item['type'] == _saveOperation && item['localKey'] != null) {
        pendingKeys.add(item['localKey']);
      }
    }

    return pendingKeys;
  }

  static Future<int> getPendingSaveCount() async {
    final pendingKeys = await getPendingSaveLocalKeys();
    return pendingKeys.length;
  }

  static Future<void> _removeMatchingOperations(
    Box<dynamic> queueBox, {
    dynamic localKey,
    int? supabaseId,
  }) async {
    final keysToDelete = <dynamic>[];

    for (final entry in queueBox.toMap().entries) {
      final rawItem = entry.value;
      if (rawItem is! Map) {
        keysToDelete.add(entry.key);
        continue;
      }

      final item = Map<String, dynamic>.from(rawItem);
      final itemLocalKey = item['localKey'];
      final itemSupabaseId = item['supabaseId'] as int?;

      final matchesLocalKey = localKey != null && itemLocalKey == localKey;
      final matchesSupabaseId =
          supabaseId != null &&
          itemSupabaseId != null &&
          itemSupabaseId == supabaseId;

      if (matchesLocalKey || matchesSupabaseId) {
        keysToDelete.add(entry.key);
      }
    }

    for (final key in keysToDelete) {
      await queueBox.delete(key);
    }
  }

  static Map<String, dynamic> _serializeEntry(EntryModel entry) {
    return {
      'supabaseId': entry.supabaseId,
      'isEdited': entry.isEdited,
      'name': entry.name,
      'flatNo': entry.flatNo,
      'mobileNumber': entry.mobileNumber,
      'date': entry.date.toIso8601String(),
      'amount': entry.amount,
      'pending': entry.pending,
      'isCash': entry.isCash,
      'fromMonth': entry.fromMonth,
      'toMonth': entry.toMonth,
      'year': entry.year,
    };
  }

  static EntryModel _deserializeEntry(Map<String, dynamic> map) {
    return EntryModel(
      supabaseId: map['supabaseId'] as int?,
      isEdited: map['isEdited'] as bool? ?? false,
      name: map['name'] as String? ?? '',
      flatNo:
          (map['flatNo'] as num?)?.toInt() ??
          int.tryParse(map['flatNo']?.toString() ?? '') ??
          0,
      mobileNumber: map['mobileNumber'] as String? ?? '',
      date:
          DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      amount:
          (map['amount'] as num?)?.toDouble() ??
          double.tryParse(map['amount']?.toString() ?? '') ??
          0,
      pending:
          (map['pending'] as num?)?.toDouble() ??
          double.tryParse(map['pending']?.toString() ?? '') ??
          0,
      isCash: map['isCash'] as bool? ?? true,
      fromMonth: map['fromMonth'] as String? ?? '',
      toMonth: map['toMonth'] as String? ?? '',
      year:
          (map['year'] as num?)?.toInt() ??
          (map['fromYear'] as num?)?.toInt() ??
          int.tryParse(map['year']?.toString() ?? '') ??
          int.tryParse(map['fromYear']?.toString() ?? '') ??
          int.tryParse(map['toYear']?.toString() ?? '') ??
          DateTime.now().year,
    );
  }
}
