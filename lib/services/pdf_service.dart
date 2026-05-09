import 'dart:io';

import 'package:k_tower/model/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

String _numberToWords(double number) {
  final int n = number.floor();

  if (n == 0) return 'Zero';

  final List<String> ones = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];

  final List<String> tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  String result = '';

  if (n >= 10000000) {
    result += '${_numberToWords((n ~/ 10000000).toDouble())} Crore ';
  }

  if (n % 10000000 >= 100000) {
    result += '${_numberToWords(((n % 10000000) ~/ 100000).toDouble())} Lakh ';
  }

  if (n % 100000 >= 1000) {
    result += '${_numberToWords(((n % 100000) ~/ 1000).toDouble())} Thousand ';
  }

  if (n % 1000 >= 100) {
    result += '${_numberToWords(((n % 1000) ~/ 100).toDouble())} Hundred ';
  }

  if (n % 100 >= 20) {
    result += '${tens[(n % 100) ~/ 10]} ';
    if ((n % 100) % 10 != 0) {
      result += '${ones[(n % 100) % 10]} ';
    }
  } else if (n % 100 > 0) {
    result += '${ones[n % 100]} ';
  }

  final int decimalPart = ((number - n) * 100).round();
  if (decimalPart > 0) {
    result += 'and ${_numberToWords(decimalPart.toDouble())} Paise ';
  }

  return result.trim();
}

class PdfService {
  Future<File> generateEntryPdf(EntryModel entry) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                color: PdfColors.deepPurple,
                padding: const pw.EdgeInsets.all(12),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'K-Tower Entry Receipt',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Entry Details',
                            style: const pw.TextStyle(
                              fontSize: 14,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(8),
                        ),
                      ),
                      child: pw.Text(
                        'Receipt #${entry.supabaseId ?? 'N/A'}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.deepPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Entry Information',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Name:', entry.name),
                    pw.SizedBox(height: 8),
                    _buildDetailRow('Flat Number:', entry.flatNo.toString()),
                    pw.SizedBox(height: 8),
                    _buildDetailRow('Mobile Number:', entry.mobileNumber),
                    pw.SizedBox(height: 8),
                    _buildDetailRow(
                      'Maintenance Period:',
                      '${entry.fromMonth} to ${entry.toMonth} ${entry.year}',
                    ),
                    pw.SizedBox(height: 8),
                    _buildDetailRow(
                      'Date:',
                      '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                    ),
                    pw.SizedBox(height: 8),
                    _buildDetailRow(
                      'Amount:',
                      'Rs. ${entry.amount.toStringAsFixed(2)}',
                    ),
                    pw.SizedBox(height: 8),
                    _buildDetailRow(
                      'Pending:',
                      'Rs. ${entry.pending.toStringAsFixed(2)}',
                    ),
                    pw.SizedBox(height: 8),
                    _buildDetailRow(
                      'Payment Mode:',
                      entry.isCash ? 'Cash' : 'Online',
                    ),
                    pw.SizedBox(height: 8),
                    _buildDetailRow(
                      'Amount in Words',
                      '${_numberToWords(entry.amount)} Only',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/entry_receipt_${entry.flatNo}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  Future<File> generateMonthlyInvoicePdf({
    required List<EntryModel> entries,
    required String fromMonth,
    required String toMonth,
    required int fromYear,
    required int toYear,
  }) async {
    final pdf = pw.Document();
    final totalAmount = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );
    final totalPending = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.pending,
    );

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            pw.Container(
              color: PdfColors.deepPurple,
              padding: const pw.EdgeInsets.all(12),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'K-Tower Monthly Invoice',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Maintenance Period: $fromMonth $fromYear to $toMonth $toYear',
                          style: const pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                    ),
                    child: pw.Text(
                      'Generated ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              'Summary',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Selected Period:',
                    '$fromMonth $fromYear to $toMonth $toYear',
                  ),
                  pw.SizedBox(height: 8),
                  _buildDetailRow('Paid Entries:', entries.length.toString()),
                  pw.SizedBox(height: 8),
                  _buildDetailRow(
                    'Total Amount:',
                    'Rs. ${totalAmount.toStringAsFixed(2)}',
                  ),
                  pw.SizedBox(height: 8),
                  _buildDetailRow(
                    'Total Pending:',
                    'Rs. ${totalPending.toStringAsFixed(2)}',
                  ),
                  pw.SizedBox(height: 8),
                  _buildDetailRow(
                    'Amount in Words:',
                    '${_numberToWords(totalAmount)} Only',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              'Maintenance Entries',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey100),
              headerStyle: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellPadding: const pw.EdgeInsets.all(6),
              headerPadding: const pw.EdgeInsets.all(6),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.2),
                1: pw.FlexColumnWidth(1.1),
                2: pw.FlexColumnWidth(1.3),
                3: pw.FlexColumnWidth(1.4),
                4: pw.FlexColumnWidth(1.2),
                5: pw.FlexColumnWidth(1.2),
              },
              headers: const [
                'Name',
                'Flat No',
                'Date',
                'Period',
                'Amount',
                'Pending',
              ],
              data: entries
                  .map(
                    (entry) => [
                      entry.name,
                      entry.flatNo.toString(),
                      '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                      '${entry.fromMonth} to ${entry.toMonth} ${entry.year}',
                      'Rs ${entry.amount.toStringAsFixed(2)}',
                      'Rs ${entry.pending.toStringAsFixed(2)}',
                    ],
                  )
                  .toList(),
            ),
            pw.SizedBox(height: 24),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/monthly_invoice_${fromMonth}_${fromYear}_${toMonth}_${toYear}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  Future<File> generateHistoryPdf(List<EntryModel> entries, int flatNo) async {
    final pdf = pw.Document();
    final totalAmount = entries.fold<double>(0, (sum, entry) => sum + entry.amount);
    final totalPending = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.pending,
    );

    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                color: PdfColors.deepPurple,
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'K-Tower History Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Flat Number: $flatNo',
                      style: const pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Summary',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      'Total Entries:',
                      entries.length.toString(),
                    ),
                    pw.SizedBox(height: 8),
                    _buildDetailRow(
                      'Total Amount:',
                      'Rs. ${totalAmount.toStringAsFixed(2)}',
                    ),
                    pw.SizedBox(height: 8),
                    _buildDetailRow(
                      'Total Pending:',
                      'Rs. ${totalPending.toStringAsFixed(2)}',
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '(${_numberToWords(totalAmount)} Only)',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Entries',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _buildTableCell('Date'),
                      _buildTableCell('Period'),
                      _buildTableCell('Name'),
                      _buildTableCell('Amount'),
                      _buildTableCell('Pending'),
                    ],
                  ),
                  ...entries.map(
                    (entry) => pw.TableRow(
                      children: [
                        _buildTableCell(
                          '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                        ),
                        _buildTableCell(
                          '${entry.fromMonth} to ${entry.toMonth} ${entry.year}',
                        ),
                        _buildTableCell(entry.name),
                        _buildTableCell(
                          'Rs ${entry.amount.toStringAsFixed(2)}',
                        ),
                        _buildTableCell(
                          'Rs ${entry.pending.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Thank you for using K-Tower!',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'This report was generated automatically.',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/history_report_flat_${flatNo}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 1,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
          ),
        ),
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> sharePdf(File file, String subject) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: subject,
      subject: subject,
    );
  }
}
