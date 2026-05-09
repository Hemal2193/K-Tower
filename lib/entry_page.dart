import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:k_tower/model/hive.dart';
import 'package:k_tower/services/entry_sync_service.dart';
import 'package:k_tower/services/sync_queue_service.dart';

class EntryPage extends StatefulWidget {
  final EntryModel? entryToEdit;

  const EntryPage({super.key, this.entryToEdit});

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
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

  final _formKey = GlobalKey<FormState>();
  final TextEditingController name = TextEditingController();
  final TextEditingController mobileNumber = TextEditingController();
  final TextEditingController flatNumber = TextEditingController();
  final TextEditingController date = TextEditingController();
  final TextEditingController amount = TextEditingController();
  final TextEditingController pending = TextEditingController();
  final TextEditingController year = TextEditingController(
    text: DateTime.now().year.toString(),
  );

  DateTime? _selectedDate;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isCash = true;
  String? _selectedFromMonth;
  String? _selectedToMonth;

  @override
  void initState() {
    super.initState();

    if (widget.entryToEdit != null) {
      _isEditing = true;
      final entry = widget.entryToEdit!;

      name.text = entry.name;
      mobileNumber.text = entry.mobileNumber;
      flatNumber.text = entry.flatNo.toString();
      _selectedDate = entry.date;
      date.text = "${entry.date.day}/${entry.date.month}/${entry.date.year}";
      amount.text = entry.amount.toString();
      pending.text = entry.pending.toString();
      _isCash = entry.isCash;
      _selectedFromMonth = _monthOptions.contains(entry.fromMonth)
          ? entry.fromMonth
          : null;
      _selectedToMonth = _monthOptions.contains(entry.toMonth)
          ? entry.toMonth
          : null;
      year.text = entry.year.toString();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000, 1),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final box = await Hive.openBox<EntryModel>(
        EntrySyncService.entriesBoxName,
      );
      final normalizedYear = _normalizeYear(year.text);

      if (normalizedYear == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Enter a valid year.')));
        return;
      }

      if (!_isPeriodValid(normalizedYear)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Select a valid period. "To" must not be before "From".',
            ),
          ),
        );
        return;
      }

      final draftEntry = EntryModel(
        supabaseId: widget.entryToEdit?.supabaseId,
        isEdited: widget.entryToEdit?.isEdited ?? false,
        name: name.text.trim(),
        flatNo: int.parse(flatNumber.text.trim()),
        mobileNumber: mobileNumber.text.trim(),
        date: _selectedDate!,
        amount: double.parse(amount.text.trim()),
        pending: pending.text.trim().isEmpty ? 0.0 : double.parse(pending.text.trim()),
        isCash: _isCash,
        fromMonth: _selectedFromMonth!,
        toMonth: _selectedToMonth!,
        year: normalizedYear,
      );

      final hasChanged =
          widget.entryToEdit != null &&
          !_hasSameValues(widget.entryToEdit!, draftEntry);

      final entryForSave = draftEntry.copyWith(
        isEdited: (widget.entryToEdit?.isEdited ?? false) || hasChanged,
      );

      final localKey = _isEditing && widget.entryToEdit != null
          ? widget.entryToEdit!.key
          : await box.add(entryForSave);

      if (_isEditing && widget.entryToEdit != null) {
        await box.put(localKey, entryForSave);
      }

      var message = _isEditing
          ? 'Entry updated successfully!'
          : 'Entry saved successfully!';

      try {
        final syncedEntry = await EntrySyncService.saveEntry(entryForSave);
        await box.put(localKey, syncedEntry);
        await SyncQueueService.clearPendingFor(
          localKey: localKey,
          supabaseId: syncedEntry.supabaseId,
        );
      } catch (_) {
        await SyncQueueService.queueSave(
          localKey: localKey,
          entry: entryForSave,
        );
        message = _isEditing
            ? 'Entry updated locally. It will sync when you are online.'
            : 'Entry saved locally. It will sync when you are online.';
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving entry: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  bool _hasSameValues(EntryModel current, EntryModel next) {
    return current.name.trim() == next.name.trim() &&
        current.flatNo == next.flatNo &&
        current.mobileNumber.trim() == next.mobileNumber.trim() &&
        current.date.year == next.date.year &&
        current.date.month == next.date.month &&
        current.date.day == next.date.day &&
        current.amount == next.amount &&
        current.pending == next.pending &&
        current.isCash == next.isCash &&
        current.fromMonth == next.fromMonth &&
        current.toMonth == next.toMonth &&
        current.year == next.year;
  }

  bool _isPeriodValid(int selectedYear) {
    if (_selectedFromMonth == null || _selectedToMonth == null) {
      return false;
    }

    return _periodIndex(_selectedFromMonth!, selectedYear) <=
        _periodIndex(_selectedToMonth!, selectedYear);
  }

  int _periodIndex(String month, int year) {
    final monthIndex = _monthOptions.indexOf(month);
    return (year * 12) + monthIndex;
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

  @override
  void dispose() {
    name.dispose();
    mobileNumber.dispose();
    flatNumber.dispose();
    date.dispose();
    amount.dispose();
    pending.dispose();
    year.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Entry")),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: "Name",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: mobileNumber,
                    decoration: const InputDecoration(
                      labelText: "Mobile No",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a mobile number';
                      }
                      if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                        return 'Mobile number must be exactly 10 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: flatNumber,
                    decoration: const InputDecoration(
                      labelText: "Flat Number",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a flat number';
                      }

                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                        return 'Please enter a valid number';
                      }

                      if (value.length < 3) {
                        return 'Invalid flat format';
                      }

                      final flat = int.parse(value.substring(value.length - 2));
                      final floor = int.parse(
                        value.substring(0, value.length - 2),
                      );

                      if (floor < 1 || floor > 13) {
                        return 'Floor must be between 1 and 13';
                      }

                      if (flat < 1 || flat > 4) {
                        return 'Each floor has only 4 flats (01-04)';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _monthOptions.contains(_selectedFromMonth)
                              ? _selectedFromMonth
                              : null,
                          decoration: const InputDecoration(
                            labelText: "From",
                            border: OutlineInputBorder(),
                          ),
                          items: _monthOptions
                              .map(
                                (month) => DropdownMenuItem<String>(
                                  value: month,
                                  child: Text(month),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedFromMonth = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Select from month';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _monthOptions.contains(_selectedToMonth)
                              ? _selectedToMonth
                              : null,
                          decoration: const InputDecoration(
                            labelText: "To",
                            border: OutlineInputBorder(),
                          ),
                          items: _monthOptions
                              .map(
                                (month) => DropdownMenuItem<String>(
                                  value: month,
                                  child: Text(month),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedToMonth = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Select to';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: year,
                          decoration: const InputDecoration(
                            labelText: "Year-(yyyy)",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (value) {
                            if (_normalizeYear(value ?? '') == null) {
                              return 'Use 2 or 4 digits';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: amount,
                              decoration: const InputDecoration(
                                labelText: "Amount Rs",
                                border: OutlineInputBorder(),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an amount';
                                }
                                final parsed = double.tryParse(value.trim());
                                if (parsed == null) {
                                  return 'Please enter a valid amount';
                                }
                                if (parsed <= 0) {
                                  return 'Amount must be greater than 0';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('Cash'),
                        selected: _isCash,
                        onSelected: (bool selected) {
                          setState(() {
                            _isCash = selected;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Online'),
                        selected: !_isCash,
                        onSelected: (bool selected) {
                          setState(() {
                            _isCash = !selected;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: pending,
                    decoration: const InputDecoration(
                      labelText: "Pending Rs",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final parsed = double.tryParse(value.trim());
                        if (parsed == null) {
                          return 'Please enter a valid pending amount';
                        }
                        if (parsed < 0) {
                          return 'Pending cannot be negative';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: date,
                    decoration: InputDecoration(
                      labelText: "Date",
                      hintText: _selectedDate == null
                          ? "Tap to select date"
                          : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                      ),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    validator: (value) {
                      if (_selectedDate == null) {
                        return 'Please select a date';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ButtonStyle(
                            elevation: WidgetStateProperty.all<double>(2),
                            shape:
                                WidgetStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Cancel"),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ButtonStyle(
                            elevation: WidgetStateProperty.all<double>(5),
                            backgroundColor: WidgetStateProperty.all<Color>(
                              Colors.deepPurple,
                            ),
                            shape:
                                WidgetStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                          ),
                          onPressed: _isSaving ? null : _saveEntry,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    "Save",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
