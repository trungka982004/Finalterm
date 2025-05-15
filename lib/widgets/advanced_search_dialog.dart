import 'package:flutter/material.dart';

class AdvancedSearchDialog extends StatefulWidget {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final bool hasAttachment;
  final String searchIn;
  const AdvancedSearchDialog({super.key, this.dateFrom, this.dateTo, this.hasAttachment = false, this.searchIn = 'all'});

  @override
  State<AdvancedSearchDialog> createState() => _AdvancedSearchDialogState();
}

class _AdvancedSearchDialogState extends State<AdvancedSearchDialog> {
  late DateTime? _dateFrom = widget.dateFrom;
  late DateTime? _dateTo = widget.dateTo;
  late bool _hasAttachment = widget.hasAttachment;
  late String _searchIn = widget.searchIn;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Advanced Search'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('From:'),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dateFrom ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _dateFrom = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_dateFrom != null ? _dateFrom!.toString().split(' ')[0] : 'Any'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('To:'),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dateTo ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _dateTo = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_dateTo != null ? _dateTo!.toString().split(' ')[0] : 'Any'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _hasAttachment,
              onChanged: (val) => setState(() => _hasAttachment = val ?? false),
              title: const Text('Has attachments'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Search in:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _searchIn,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'subject', child: Text('Subject')),
                    DropdownMenuItem(value: 'sender', child: Text('Sender')),
                    DropdownMenuItem(value: 'body', child: Text('Body')),
                  ],
                  onChanged: (val) => setState(() => _searchIn = val ?? 'all'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'dateFrom': _dateFrom,
              'dateTo': _dateTo,
              'hasAttachment': _hasAttachment,
              'searchIn': _searchIn,
            });
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
} 