import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_tower/model/hive.dart';
import 'package:k_tower/services/pdf_service.dart';
import 'package:k_tower/widgets/pdf_preview_page.dart';

class MonthlyInvoiceSheet {
  final List<EntryModel> entries;
  final PdfService pdfService;
  final BuildContext context;

  MonthlyInvoiceSheet({
    required this.entries,
    required this.pdfService,
    required this.context,
  });

  static const List<String> monthOptions = [
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

  static const Map<String, int> monthOrder = {
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

  void show() {
    String? selectedFromMonth;
    String? selectedToMonth;
    final currentYear = DateTime.now().year;
    final fromYearController = TextEditingController(text: currentYear.toString());
    final toYearController = TextEditingController(text: currentYear.toString());

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Invoice',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select the month range to include in the PDF.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedFromMonth,
                            decoration: const InputDecoration(
                              labelText: 'From',
                              border: OutlineInputBorder(),
                            ),
                            items: monthOptions
                                .map(
                                  (month) => DropdownMenuItem<String>(
                                    value: month,
                                    child: Text(month),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setModalState(() {
                                selectedFromMonth = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: fromYearController,
                            decoration: const InputDecoration(
                              labelText: 'Year-(yyyy)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedToMonth,
                            decoration: const InputDecoration(
                              labelText: 'To',
                              border: OutlineInputBorder(),
                            ),
                            items: monthOptions
                                .map(
                                  (month) => DropdownMenuItem<String>(
                                    value: month,
                                    child: Text(month),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setModalState(() {
                                selectedToMonth = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: toYearController,
                            decoration: const InputDecoration(
                              labelText: 'Year-(yyyy)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (selectedFromMonth == null ||
                              selectedToMonth == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Select both "from" and "to" months.',
                                ),
                              ),
                            );
                            return;
                          }

                          final selectedFromYear = _normalizeYear(
                            fromYearController.text,
                          );
                          final selectedToYear = _normalizeYear(
                            toYearController.text,
                          );

                          if (selectedFromYear == null ||
                              selectedToYear == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Enter valid years.'),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(context);
                          await _openMonthlyInvoicePreview(
                            fromMonth: selectedFromMonth!,
                            toMonth: selectedToMonth!,
                            fromYear: selectedFromYear,
                            toYear: selectedToYear,
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Generate PDF'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openMonthlyInvoicePreview({
    required String fromMonth,
    required String toMonth,
    required int fromYear,
    required int toYear,
  }) async {
    final filterStart = _periodIndex(fromMonth, fromYear);
    final filterEnd = _periodIndex(toMonth, toYear);

    if (filterEnd < filterStart) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a valid month-year range for the invoice.'),
        ),
      );
      return;
    }

    final selectedEntries =
        entries
            .where(
              (entry) => _matchesMonthRange(
                entry,
                fromMonth,
                toMonth,
                fromYear,
                toYear,
              ),
            )
            .toList()
          ..sort((a, b) {
            final flatCompare = a.flatNo.compareTo(b.flatNo);
            if (flatCompare != 0) {
              return flatCompare;
            }
            return a.date.compareTo(b.date);
          });

    if (selectedEntries.isEmpty) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No entries found for the selected months.'),
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      if (!context.mounted) {
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final pdfFile = await pdfService.generateMonthlyInvoicePdf(
        entries: selectedEntries,
        fromMonth: fromMonth,
        toMonth: toMonth,
        fromYear: fromYear,
        toYear: toYear,
      );

      if (!context.mounted) {
        return;
      }

      Navigator.pop(context); // Close loading dialog

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewPage(
            pdfFile: pdfFile,
            title: 'Monthly Invoice',
            shareSubject:
                'K-Tower Monthly Invoice $fromMonth $fromYear to $toMonth $toYear',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  bool _matchesMonthRange(
    EntryModel entry,
    String selectedFromMonth,
    String selectedToMonth,
    int selectedFromYear,
    int selectedToYear,
  ) {
    final filterStart = _periodIndex(selectedFromMonth, selectedFromYear);
    final filterEnd = _periodIndex(selectedToMonth, selectedToYear);
    final entryStart = _periodIndex(entry.fromMonth, entry.year);
    final entryEnd = _periodIndex(entry.toMonth, entry.year);

    if (filterEnd < filterStart || entryEnd < entryStart) {
      return false;
    }

    return entryStart >= filterStart && entryEnd <= filterEnd;
  }

  int _periodIndex(String month, int year) {
    final monthOrderValue = monthOrder[month] ?? 1;
    return (year * 12) + monthOrderValue;
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
}