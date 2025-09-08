import 'dart:io';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:path_provider/path_provider.dart';

class ReportService {
  static final TransactionRepository _transactionRepo =
      TransactionRepository(DatabaseHelper.instance);

  /// Export transaksi ke file Excel
  static Future<void> exportTransactionsToExcel({
    required List<dynamic> transactions,
    required String reportTitle,
    DateTime? startDate,
    DateTime? endDate,
    required BuildContext context,
  }) async {
    try {
      final workbook = excel.Excel.createExcel();
      final sheetName = workbook.sheets.keys.first;
      final sheet = workbook[sheetName];

      _addReportHeader(sheet, reportTitle, startDate, endDate);
      _addTableHeaders(sheet, startDate, endDate);

      await _addTransactionData(sheet, transactions, startDate, endDate);

      await _saveAndExportFile(workbook, context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  /// ===== STYLE SECTION =====
  static excel.Border _thinBorder() => excel.Border(
        borderStyle: excel.BorderStyle.Thin,
        borderColorHex: excel.ExcelColor.fromHexString("#FF000000"),
      );

  static final titleStyle = excel.CellStyle(
    bold: true,
    fontSize: 20,
    backgroundColorHex:
        excel.ExcelColor.fromHexString("#FFCCE5FF"), // Biru muda
    horizontalAlign: excel.HorizontalAlign.Center,
    verticalAlign: excel.VerticalAlign.Center,
  );

  static final periodStyle = excel.CellStyle(
    italic: true,
    fontSize: 14,
    fontColorHex: excel.ExcelColor.fromHexString("#FF666666"),
    horizontalAlign: excel.HorizontalAlign.Center,
    verticalAlign: excel.VerticalAlign.Center,
  );

  static final tableHeaderStyle = excel.CellStyle(
    backgroundColorHex:
        excel.ExcelColor.fromHexString("#FF4F81BD"), // Biru gelap
    fontColorHex: excel.ExcelColor.fromHexString("#FFFFFFFF"), // Putih
    bold: true,
    horizontalAlign: excel.HorizontalAlign.Center,
    verticalAlign: excel.VerticalAlign.Center,
    topBorder: _thinBorder(),
    bottomBorder: _thinBorder(),
    leftBorder: _thinBorder(),
    rightBorder: _thinBorder(),
  );

  static final zebraStyleOdd = excel.CellStyle(
    backgroundColorHex: excel.ExcelColor.fromHexString("#FFFFFFFF"), // Putih
    topBorder: _thinBorder(),
    bottomBorder: _thinBorder(),
    leftBorder: _thinBorder(),
    rightBorder: _thinBorder(),
  );

  static final zebraStyleEven = excel.CellStyle(
    backgroundColorHex: excel.ExcelColor.fromHexString("#FFF2F2F2"), // Abu muda
    topBorder: _thinBorder(),
    bottomBorder: _thinBorder(),
    leftBorder: _thinBorder(),
    rightBorder: _thinBorder(),
  );

  static final numberStyle = excel.CellStyle(
    numberFormat: excel.CustomNumericNumFormat(formatCode: "#,##0"),
    horizontalAlign: excel.HorizontalAlign.Right,
    topBorder: _thinBorder(),
    bottomBorder: _thinBorder(),
    leftBorder: _thinBorder(),
    rightBorder: _thinBorder(),
  );

  static final detailItemHeaderStyle = excel.CellStyle(
    backgroundColorHex:
        excel.ExcelColor.fromHexString("#FFFFE699"), // Kuning lembut
    bold: true,
    italic: true,
    topBorder: _thinBorder(),
    bottomBorder: _thinBorder(),
    leftBorder: _thinBorder(),
    rightBorder: _thinBorder(),
  );

  /// ===== HEADER REPORT =====
  static void _addReportHeader(
    excel.Sheet sheet,
    String title,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    // Judul
    sheet.merge(excel.CellIndex.indexByString("A1"),
        excel.CellIndex.indexByString("G1"));
    sheet.cell(excel.CellIndex.indexByString("A1"))
      ..value = excel.TextCellValue(title)
      ..cellStyle = titleStyle;

    // Periode
    if (startDate != null && endDate != null) {
      final dateRange =
          'Periode: ${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}';
      sheet.merge(excel.CellIndex.indexByString("A2"),
          excel.CellIndex.indexByString("G2"));
      sheet.cell(excel.CellIndex.indexByString("A2"))
        ..value = excel.TextCellValue(dateRange)
        ..cellStyle = periodStyle;
    }
  }

  /// ===== HEADER TABLE =====
  static void _addTableHeaders(
    excel.Sheet sheet,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final headers = [
      'No',
      'Tanggal',
      'Nama Pelanggan',
      'No HP Pelanggan',
      'Diskon (Rp)',
      'Total (Rp)',
      'Added By'
    ];

    final headerRow = (startDate != null && endDate != null) ? 2 : 1;

    sheet
      ..setColumnWidth(0, 5)
      ..setColumnWidth(1, 25)
      ..setColumnWidth(2, 25)
      ..setColumnWidth(3, 18)
      ..setColumnWidth(4, 15)
      ..setColumnWidth(5, 15)
      ..setColumnWidth(6, 20);

    for (int col = 0; col < headers.length; col++) {
      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: col, rowIndex: headerRow))
        ..value = excel.TextCellValue(headers[col])
        ..cellStyle = tableHeaderStyle;
    }
  }

  /// ===== DATA TRANSAKSI =====
  static Future<void> _addTransactionData(
    excel.Sheet sheet,
    List<dynamic> transactions,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final headerRow = (startDate != null && endDate != null) ? 2 : 1;
    int currentRow = headerRow + 1;

    for (int i = 0; i < transactions.length; i++) {
      final item = transactions[i];
      final transaction = item.transaction;

      final rowStyle = (i % 2 == 0) ? zebraStyleEven : zebraStyleOdd;

      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 0, rowIndex: currentRow))
        ..value = excel.IntCellValue(i + 1)
        ..cellStyle = rowStyle;

      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 1, rowIndex: currentRow))
        ..value = excel.TextCellValue(
            DateFormat('dd MMM yyyy HH:mm:ss').format(transaction.createdAt))
        ..cellStyle = rowStyle;

      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 2, rowIndex: currentRow))
        ..value = excel.TextCellValue(item.customerName)
        ..cellStyle = rowStyle;

      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 3, rowIndex: currentRow))
        ..value = excel.TextCellValue(item.customerPhone)
        ..cellStyle = rowStyle;

      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 4, rowIndex: currentRow))
        ..value = excel.TextCellValue(_formatPrice(transaction.discountPrice))
        ..cellStyle = numberStyle;

      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 5, rowIndex: currentRow))
        ..value = excel.TextCellValue(_formatPrice(transaction.finalPrice))
        ..cellStyle = numberStyle;

      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 6, rowIndex: currentRow))
        ..value = excel.TextCellValue(item.addedBy)
        ..cellStyle = rowStyle;

      // Detail item
      final items = await _transactionRepo.getTransactionItems(transaction.id);

      if (items.isNotEmpty) {
        currentRow++;
        _addItemSectionHeader(sheet, currentRow);

        currentRow++;
        _addItemTableHeader(sheet, currentRow);

        for (final item in items) {
          currentRow++;
          final itemDetails =
              await _transactionRepo.getItemDetails(item.masterDataId);

          sheet.cell(excel.CellIndex.indexByColumnRow(
              columnIndex: 1, rowIndex: currentRow))
            ..value = excel.TextCellValue(itemDetails['name'] ?? 'Unknown Item')
            ..cellStyle = zebraStyleOdd;

          sheet.cell(excel.CellIndex.indexByColumnRow(
              columnIndex: 2, rowIndex: currentRow))
            ..value = excel.IntCellValue(item.qty)
            ..cellStyle = numberStyle;

          sheet.cell(excel.CellIndex.indexByColumnRow(
              columnIndex: 3, rowIndex: currentRow))
            ..value = excel.TextCellValue(_formatPrice(itemDetails['price']))
            ..cellStyle = numberStyle;

          sheet.cell(excel.CellIndex.indexByColumnRow(
              columnIndex: 4, rowIndex: currentRow))
            ..value = excel.TextCellValue(_formatPrice(item.totalPrice))
            ..cellStyle = numberStyle;
        }
        currentRow++;
      } else {
        currentRow++;
      }
    }
  }

  /// Header section detail item
  static void _addItemSectionHeader(excel.Sheet sheet, int row) {
    sheet.merge(
      excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      excel.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
    );
    sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = excel.TextCellValue("Detail Item:")
      ..cellStyle = detailItemHeaderStyle;
  }

  /// Header tabel detail item
  static void _addItemTableHeader(excel.Sheet sheet, int row) {
    final headers = [
      '',
      'Nama Produk',
      'Qty',
      'Harga Satuan',
      'Subtotal',
      '',
      ''
    ];
    for (int col = 0; col < headers.length; col++) {
      sheet.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        ..value = excel.TextCellValue(headers[col])
        ..cellStyle = tableHeaderStyle;
    }
  }

  /// Simpan file
  static Future<void> _saveAndExportFile(
    excel.Excel workbook,
    BuildContext context,
  ) async {
    final directory = await getTemporaryDirectory();
    final fileName =
        'Laporan_Penjualan_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    final bytes = workbook.save();
    if (bytes == null) return;

    await file.writeAsBytes(bytes);

    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan Laporan',
      fileName: fileName,
      allowedExtensions: ['xlsx'],
      type: FileType.custom,
    );

    if (savedPath != null) {
      final finalPath =
          savedPath.endsWith('.xlsx') ? savedPath : '$savedPath.xlsx';
      await file.copy(finalPath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan berhasil diekspor')),
        );
      }
    }
  }

  /// Format harga
  static String _formatPrice(int price) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    return formatter.format(price);
  }
}
