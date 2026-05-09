import 'package:flutter/material.dart';
import 'package:k_tower/model/hive.dart';

class EntryListItem extends StatelessWidget {
  final EntryModel entry;
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final bool showMenu;
  final bool isPendingSync;

  const EntryListItem({
    super.key,
    required this.entry,
    this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
    this.showMenu = true,
    this.isPendingSync = false,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatDate(entry.date);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        subtitleTextStyle: TextStyle(fontSize: 14, color: Colors.grey[800]),
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple,
          child: Text(
            entry.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                entry.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (entry.isEdited)
              Container(
                margin: const EdgeInsets.only(left: 5, top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Edited',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${entry.fromMonth} to ${entry.toMonth}'),
            const SizedBox(height: 2),
            Text('Flat No: ${entry.flatNo}'),
            const SizedBox(height: 2),
            Text('Date: $formattedDate'),
            const SizedBox(height: 2),
            if (isPendingSync) ...[
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.sync, size: 14, color: Colors.orange),
                  SizedBox(width: 4),
                  Text(
                    'Pending sync',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        horizontalTitleGap: 12,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs ${entry.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'P ${entry.pending.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: entry.pending > 0 ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
            if (showMenu) ...[
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (String result) {
                  switch (result) {
                    case 'Edit':
                      onEdit();
                      break;
                    case 'Delete':
                      onDelete();
                      break;
                    case 'Share':
                      onShare();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'Share',
                    child: Text('Share'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
