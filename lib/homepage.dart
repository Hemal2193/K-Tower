import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:k_tower/entry_page.dart';
import 'package:k_tower/history_page.dart';
import 'package:k_tower/model/hive.dart';
import 'package:k_tower/services/entry_sync_service.dart';
import 'package:k_tower/services/pdf_service.dart';
import 'package:k_tower/services/sync_queue_service.dart';
import 'package:k_tower/widgets/entry_list_item.dart';
import 'package:k_tower/widgets/fab_options_sheet.dart';
import 'package:k_tower/widgets/logout_dialog.dart';
import 'package:k_tower/widgets/monthly_invoice_sheet.dart';
import 'package:k_tower/widgets/pdf_preview_page.dart';
import 'package:k_tower/widgets/search_bar.dart' as search_bar;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  List<EntryModel> _entries = [];
  List<EntryModel> _filteredEntries = [];
  Set<dynamic> _pendingSyncKeys = {};
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final PdfService _pdfService = PdfService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load local data instantly, then sync in background
    _loadLocalThenSync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadLocalThenSync();
    }
  }

  String normalizePhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.startsWith('91')) {
      if (cleaned.length > 10) {
        cleaned = cleaned.substring(cleaned.length - 10);
      } else if (cleaned.length == 12) {
        cleaned = cleaned.substring(2);
      }
    } else if (cleaned.length > 10) {
      cleaned = cleaned.substring(cleaned.length - 10);
    }

    return cleaned;
  }

  /// Loads local entries instantly (no network), then syncs in the background.
  Future<void> _loadLocalThenSync() async {
    try {
      // Phase 1: Show local data IMMEDIATELY — no network calls
      final localEntries = await EntrySyncService.loadLocalEntries();
      final pendingSyncKeys = await SyncQueueService.getPendingSaveLocalKeys();

      if (!mounted) return;

      setState(() {
        _entries = localEntries;
        _filteredEntries = localEntries;
        _pendingSyncKeys = pendingSyncKeys;
        _isLoading = false;
      });

      // Phase 2: Process sync queue + cloud restore in background
      // This no longer blocks the UI from showing data
      _syncInBackground();
    } catch (e) {
      // If local loading fails (unlikely), fall back to the full load
      _loadEntries();
    }
  }

  /// Performs network-dependent operations in the background
  /// without showing a loading spinner.
  Future<void> _syncInBackground() async {
    try {
      final queueResult = await SyncQueueService.processQueue();
      final result = await EntrySyncService.loadEntries();

      if (!mounted) return;

      setState(() {
        _entries = result.entries;
        _filteredEntries = result.entries;
        _pendingSyncKeys = <dynamic>{};
        // Keep _isLoading = false — we never re-show the spinner
      });

      if (result.restoredFromCloud && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entries restored from Cloud.')),
        );
      } else if (queueResult.syncedCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Synced ${queueResult.syncedCount} pending change${queueResult.syncedCount == 1 ? '' : 's'}.',
            ),
          ),
        );
      }
    } catch (_) {
      // Silently swallow background errors — the user already sees local data
    }
  }

  // Keep the original _loadEntries for fallback and pull-to-refresh
  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final queueResult = await SyncQueueService.processQueue();
      final result = await EntrySyncService.loadEntries();
      final pendingSyncKeys = await SyncQueueService.getPendingSaveLocalKeys();

      if (!mounted) {
        return;
      }

      setState(() {
        _entries = result.entries;
        _filteredEntries = result.entries;
        _pendingSyncKeys = pendingSyncKeys;
        _isLoading = false;
      });

      if (result.restoredFromCloud) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entries restored from Cloud.')),
        );
      } else if (queueResult.syncedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Synced ${queueResult.syncedCount} pending change${queueResult.syncedCount == 1 ? '' : 's'}.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading entries: $e')));
    }
  }

  void _showPendingSyncInfo() {
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No entries to sync.')),
      );
      return;
    }

    final pendingCount = _pendingSyncKeys.length;
    final message = pendingCount == 0
        ? 'All entries are synced.'
        : '$pendingCount entr${pendingCount == 1 ? 'y is' : 'ies are'} pending sync.';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _search(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredEntries = _entries;
      });
      return;
    }

    final normalizedQuery = normalizePhone(query);

    setState(() {
      _filteredEntries = _entries.where((entry) {
        final nameMatch = entry.name.toLowerCase().contains(
          query.toLowerCase().trim(),
        );
        final flatMatch = entry.flatNo.toString().contains(query.trim());

        bool phoneMatch = false;
        if (query.trim().isNotEmpty &&
            query.trim().contains(RegExp(r'^[0-9+\s-()]+$'))) {
          final entryPhone = normalizePhone(entry.mobileNumber);
          phoneMatch =
              entryPhone.contains(normalizedQuery) ||
              entry.mobileNumber.contains(query.trim());
        }

        return nameMatch || flatMatch || phoneMatch;
      }).toList();
    });
  }

  void _editEntry(EntryModel entry) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EntryPage(entryToEdit: entry)),
    ).then((result) {
      if (result == true) {
        _loadLocalThenSync();
      }
    });
  }

  void _openHistory(EntryModel entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryPage(flatNo: entry.flatNo),
      ),
    );
  }

  void _showDeleteConfirmation(EntryModel entry) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Entry'),
          content: Text(
            'Are you sure you want to delete the entry for ${entry.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteEntry(entry);
                Navigator.of(context).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEntry(EntryModel entry) async {
    try {
      final box = await Hive.openBox<EntryModel>(
        EntrySyncService.entriesBoxName,
      );
      final localKey = entry.key;
      await box.delete(localKey);

      var message = 'Entry deleted successfully!';

      try {
        await EntrySyncService.deleteEntry(entry.supabaseId);
        await SyncQueueService.clearPendingFor(
          localKey: localKey,
          supabaseId: entry.supabaseId,
        );
      } catch (_) {
        await SyncQueueService.queueDelete(
          localKey: localKey,
          supabaseId: entry.supabaseId,
        );
        message = entry.supabaseId == null
            ? 'Entry deleted locally.'
            : 'Entry deleted locally. It will sync when you are online.';
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

      _loadLocalThenSync();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting entry: $e')));
    }
  }

  Future<void> _shareEntry(EntryModel entry) async {
    try {
      final pdfFile = await _pdfService.generateEntryPdf(entry);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewPage(
            pdfFile: pdfFile,
            title: 'Receipt',
            shareSubject: 'K-Tower Entry Receipt for ${entry.name}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    }
  }

  void _showFabOptions() {
    FabOptionsSheet(
      onNewEntry: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EntryPage(),
          ),
        ).then((_) {
          _loadLocalThenSync();
        });
      },
      onMonthlyInvoice: () {
        MonthlyInvoiceSheet(
          entries: _entries,
          pdfService: _pdfService,
          context: context,
        ).show();
      },
    ).show(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('K-Tower', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurpleAccent,
        actions: [
          IconButton(
            onPressed: _showPendingSyncInfo,
            icon: Icon(
              _entries.isEmpty
                  ? Icons.sync_disabled
                  : _pendingSyncKeys.isEmpty
                  ? Icons.sync
                  : Icons.sync_problem,
              color: Colors.white,
            ),
            tooltip: _entries.isEmpty
                ? 'No entries'
                : _pendingSyncKeys.isEmpty
                ? 'All synced'
                : '${_pendingSyncKeys.length} pending sync',
          ),
          IconButton(
            onPressed: () => LogoutDialog.show(context),
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sign out',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFabOptions,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                search_bar.CustomSearchBar(
                  controller: _searchController,
                  onChanged: _search,
                ),
                Expanded(
                  child: _filteredEntries.isEmpty
                      ? const Center(child: Text('No Entries'))
                      : RefreshIndicator(
                          onRefresh: _loadEntries,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _filteredEntries.length,
                            itemBuilder: (context, index) {
                              final entry =
                                  _filteredEntries[_filteredEntries.length -
                                      1 -
                                      index];

                              return EntryListItem(
                                entry: entry,
                                isPendingSync: _pendingSyncKeys.contains(
                                  entry.key,
                                ),
                                onTap: () => _openHistory(entry),
                                onEdit: () => _editEntry(entry),
                                onDelete: () => _showDeleteConfirmation(entry),
                                onShare: () => _shareEntry(entry),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}