import 'package:flutter/material.dart';
import 'package:k_tower/entry_page.dart';

class FabOptionsSheet {
  final VoidCallback? onNewEntry;
  final VoidCallback? onMonthlyInvoice;

  const FabOptionsSheet({
    this.onNewEntry,
    this.onMonthlyInvoice,
  });

  void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('New Entry'),
                  subtitle: const Text('Add a fresh maintenance entry'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (onNewEntry != null) {
                      onNewEntry!();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EntryPage(),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: const Text('Monthly Invoice'),
                  subtitle: const Text('Generate month-wise maintenance PDF'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (onMonthlyInvoice != null) {
                      onMonthlyInvoice!();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}