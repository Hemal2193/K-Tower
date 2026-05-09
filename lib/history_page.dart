import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:k_tower/model/hive.dart';
import 'package:k_tower/services/pdf_service.dart';
import 'package:k_tower/services/sync_queue_service.dart';
import 'package:k_tower/widgets/entry_list_item.dart';
import 'package:k_tower/widgets/pdf_preview_page.dart';

class HistoryPage extends StatefulWidget {
  final int flatNo;

  const HistoryPage({super.key, required this.flatNo});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static final int _currentYear = DateTime.now().year;
  static const List<String> _monthOptions = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const Map<String, int> _monthOrder = {
    'Jan': 1,
    'Feb': 2,
    'Mar': 3,
    'Apr': 4,
    'May': 5,
    'Jun': 6,
    'Jul': 7,
    'Aug': 8,
    'Sep': 9,
    'Oct': 10,
    'Nov': 11,
    'Dec': 12,
  };

  List<EntryModel> _allEntries = [];
  List<EntryModel> _entries = [];
  Set<dynamic> _pendingSyncKeys = {};
  bool _isLoading = true;
  String? _selectedFromMonth;
  String? _selectedToMonth;
  final TextEditingController _fromYearController = TextEditingController(
    text: _currentYear.toString(),
  );
  final TextEditingController _toYearController = TextEditingController(
    text: _currentYear.toString(),
  );

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final box = await Hive.openBox<EntryModel>('entries');
      final pendingSyncKeys = await SyncQueueService.getPendingSaveLocalKeys();
      final entries = box.values
          .where((entry) => entry.flatNo == widget.flatNo)
          .toList();

      entries.sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) {
        return;
      }

      setState(() {
        _allEntries = entries;
        _entries = List<EntryModel>.from(entries);
        _pendingSyncKeys = pendingSyncKeys;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading history: $e')));
    }
  }

  double get _totalAmount =>
      _entries.fold(0, (sum, entry) => sum + entry.amount);
  double get _totalPending =>
      _entries.fold(0, (sum, entry) => sum + entry.pending);

  void _onMonthFilterChanged({String? fromMonth, String? toMonth}) {
    setState(() {
      if (fromMonth != null) {
        _selectedFromMonth = fromMonth;
      }
      if (toMonth != null) {
        _selectedToMonth = toMonth;
      }
      _applyMonthFilter();
    });
  }

  void _applyMonthFilter() {
    final selectedFromYear = _normalizeYear(_fromYearController.text);
    final selectedToYear = _normalizeYear(_toYearController.text);

    final filtered = _allEntries.where((entry) {
      if (_selectedFromMonth == null && _selectedToMonth == null) {
        return true;
      }

      if (_selectedFromMonth != null && _selectedToMonth == null) {
        return selectedFromYear != null &&
            entry.fromMonth == _selectedFromMonth &&
            entry.year == selectedFromYear;
      }

      if (_selectedFromMonth == null && _selectedToMonth != null) {
        return selectedToYear != null &&
            entry.toMonth == _selectedToMonth &&
            entry.year == selectedToYear;
      }

      if (selectedFromYear == null || selectedToYear == null) {
        return false;
      }

      final filterStart = _periodIndex(_selectedFromMonth!, selectedFromYear);
      final filterEnd = _periodIndex(_selectedToMonth!, selectedToYear);
      final entryStart = _periodIndex(entry.fromMonth, entry.year);
      final entryEnd = _periodIndex(entry.toMonth, entry.year);

      if (filterEnd < filterStart || entryEnd < entryStart) {
        return false;
      }

      return entryStart >= filterStart && entryEnd <= filterEnd;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    _entries = filtered;
  }

  int _periodIndex(String month, int year) {
    final monthOrder = _monthOrder[month] ?? 1;
    return (year * 12) + monthOrder;
  }

  DropdownButtonFormField<String> _buildMonthDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: _monthOptions.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: _monthOptions
          .map(
            (month) =>
                DropdownMenuItem<String>(value: month, child: Text(month)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildYearField({required TextEditingController controller}) {
    final errorText = controller.text.isEmpty
        ? null
        : _normalizeYear(controller.text) == null
        ? 'Use YYYY'
        : null;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Year-(yyyy)',
        errorText: errorText,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      onChanged: (_) => _onMonthFilterChanged(),
    );
  }

  int? _normalizeYear(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final parsed = int.tryParse(trimmed);
    if (parsed == null) {
      return null;
    }

    if (trimmed.length <= 2) {
      return 2000 + parsed;
    }

    if (trimmed.length != 4) {
      return null;
    }

    if (parsed < 2000 || parsed > 2100) {
      return null;
    }

    return parsed;
  }

  final PdfService _pdfService = PdfService();

  Future<void> _openPdfPreview(EntryModel entry) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final pdfFile = await _pdfService.generateEntryPdf(entry);

      await Navigator.push(
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
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flat ${widget.flatNo} History'),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Previous entries: ${_entries.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Total amount: Rs ${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total pending: Rs ${_totalPending.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    'Filter by Month Range',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.deepPurpleAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMonthDropdown(
                          label: 'From',
                          value: _selectedFromMonth,
                          onChanged: (value) =>
                              _onMonthFilterChanged(fromMonth: value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildYearField(controller: _fromYearController),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMonthDropdown(
                          label: 'To',
                          value: _selectedToMonth,
                          onChanged: (value) =>
                              _onMonthFilterChanged(toMonth: value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildYearField(controller: _toYearController),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _entries.isEmpty
                      ? const Center(
                          child: Text('No previous entries for this flat.'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[_entries.length - 1 - index];

                            return EntryListItem(
                              entry: entry,
                              isPendingSync: _pendingSyncKeys.contains(
                                entry.key,
                              ),
                              onTap: () => _openPdfPreview(entry),
                              onEdit: () {},
                              onDelete: () {},
                              onShare: () {},
                              showMenu: false,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _fromYearController.dispose();
    _toYearController.dispose();
    super.dispose();
  }
}
