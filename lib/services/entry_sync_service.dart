import 'package:hive/hive.dart';
import 'package:k_tower/model/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of loading entries from local storage with optional cloud sync
class LoadEntriesResult {
  final List<EntryModel> entries;
  final bool restoredFromCloud;

  LoadEntriesResult({required this.entries, required this.restoredFromCloud});
}

class EntrySyncService {
  EntrySyncService._();

  static const String entriesBoxName = 'entries';
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _schema = 'public';
  static const String _table = 'invoices';

  static String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const AuthException('No authenticated user found.');
    }
    return userId;
  }

  /// Load entries from local Hive storage only. No network calls.
  /// This is instant and should be used to show cached data immediately.
  static Future<List<EntryModel>> loadLocalEntries() async {
    final box = await Hive.openBox<EntryModel>(entriesBoxName);
    return box.values.toList();
  }

  static Future<EntryModel> saveEntry(EntryModel entry) async {
    final userId = _requireUserId();

    if (entry.supabaseId == null) {
      final response = await _client
          .schema(_schema)
          .from(_table)
          .insert(_toSupabaseMap(entry, userId))
          .select('id')
          .single();

      return entry.copyWith(supabaseId: response['id'] as int?);
    }

    final response = await _client
        .schema(_schema)
        .from(_table)
        .upsert({
          'id': entry.supabaseId,
          ..._toSupabaseMap(entry, userId),
        })
        .select('id')
        .single();

    return entry.copyWith(supabaseId: response['id'] as int?);
  }

  static Future<void> deleteEntry(int? supabaseId) async {
    if (supabaseId == null) {
      return;
    }

    final userId = _requireUserId();

    await _client
        .schema(_schema)
        .from(_table)
        .delete()
        .eq('id', supabaseId)
        .eq('user_id', userId);
  }

  static Future<List<EntryModel>> fetchEntries() async {
    final userId = _requireUserId();

    final response = await _client
        .schema(_schema)
        .from(_table)
        .select(
          'id, name, flat_no, mobile_no, date, amount, pending, isEdited, from_month, to_month, year',
        )
        .eq('user_id', userId)
        .order('date');

    return (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_fromSupabaseMap)
        .toList();
  }

  static Map<String, dynamic> _toSupabaseMap(EntryModel entry, String userId) {
    return {
      'user_id': userId,
      'name': entry.name,
      'flat_no': entry.flatNo.toString(),
      'mobile_no': entry.mobileNumber,
      'date': _formatDate(entry.date),
      'amount': entry.amount,
      'pending': entry.pending,
      'isEdited': entry.isEdited,
      'from_month': entry.fromMonth,
      'to_month': entry.toMonth,
      'year': entry.year,
    };
  }

  static EntryModel _fromSupabaseMap(Map<String, dynamic> row) {
    return EntryModel(
      supabaseId: row['id'] as int?,
      name: row['name'] as String? ?? '',
      flatNo: int.tryParse(row['flat_no']?.toString() ?? '') ?? 0,
      mobileNumber: row['mobile_no'] as String? ?? '',
      date: DateTime.parse(row['date'] as String),
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      pending: (row['pending'] as num?)?.toDouble() ?? 0,
      isEdited: row['isEdited'] as bool? ?? false,
      fromMonth: row['from_month'] as String? ?? '',
      toMonth: row['to_month'] as String? ?? '',
      year:
          (row['year'] as num?)?.toInt() ??
          (row['from_year'] as num?)?.toInt() ??
          (row['to_year'] as num?)?.toInt() ??
          DateTime.now().year,
    );
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Loads entries from local Hive storage, syncing from Supabase if local storage is empty.
  /// Returns [LoadEntriesResult] containing the entries and a flag indicating if they were restored from cloud.
  static Future<LoadEntriesResult> loadEntries() async {
    final box = await Hive.openBox<EntryModel>(entriesBoxName);
    bool restoredFromCloud = false;

    if (box.isEmpty) {
      try {
        final remoteEntries = await fetchEntries();
        if (remoteEntries.isNotEmpty) {
          await box.addAll(remoteEntries);
          restoredFromCloud = true;
        }
      } catch (_) {
        // Keep the app usable offline. If cloud restore fails, we simply
        // return the current local state instead of surfacing a hard error.
      }
    }

    final entries = box.values.toList();
    return LoadEntriesResult(
      entries: entries,
      restoredFromCloud: restoredFromCloud,
    );
  }
}