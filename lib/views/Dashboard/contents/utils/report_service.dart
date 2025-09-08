import 'dart:io';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meko_poin/services/database_helper.dart';
import 'package:meko_poin/services/transaction_repository.dart';
import 'package:path_provider/path_provider.dart';

extension StringCaseExtension on String {
  String toAllCaps() {
    return toUpperCase();
  }

  String toSentenceCase() {
    return toBeginningOfSentenceCase(this) ?? this;
  }
}

class ReportService {
  static final TransactionRepository _transactionRepo =
      TransactionRepository(DatabaseHelper.instance);

  // TAMBAHKAN CONSTANT UNTUK ROW HEIGHT
  static const double _titleRowHeight = 30.0;
  static const double _headerRowHeight = 22.0;
  static const double _transactionRowHeight = 20.0;
  static const double _detailRowHeight = 18.0;

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

      final fileName = _generateFileName(startDate, endDate);

      await _saveAndExportFile(workbook, context, fileName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  /// GENERATE FILE NAME BERDASARKAN FILTER
  static String _generateFileName(DateTime? startDate, DateTime? endDate) {
    final dateFormat = DateFormat('dd MMM yyyy');

    if (startDate != null && endDate != null) {
      // Dengan filter periode
      if (startDate == endDate) {
        return 'Laporan Penjualan ${dateFormat.format(startDate)}';
      } else {
        return 'Laporan Penjualan ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
      }
    } else {
      // Tanpa filter - gunakan tanggal hari ini
      return 'Laporan Penjualan ${dateFormat.format(DateTime.now())}';
    }
  }

  /// ===== STYLE SECTION - UPDATED =====
  static excel.Border _thinBorder() => excel.Border(
        borderStyle: excel.BorderStyle.Thin,
        borderColorHex: excel.ExcelColor.fromHexString("#FF000000"),
      );

  static final titleStyle = excel.CellStyle(
    bold: true,
    fontSize: 20,
    backgroundColorHex: excel.ExcelColor.fromHexString("#FFB3CEFB"),
    fontColorHex: excel.ExcelColor.fromHexString("#FF000000"),
    horizontalAlign: excel.HorizontalAlign.Center,
    verticalAlign: excel.VerticalAlign.Center,
  );

  static final periodStyle = excel.CellStyle(
    italic: true,
    fontSize: 14,
    backgroundColorHex: excel.ExcelColor.fromHexString("#FFD9E7FD"),
    fontColorHex: excel.ExcelColor.fromHexString("#FF666666"),
    horizontalAlign: excel.HorizontalAlign.Center,
    verticalAlign: excel.VerticalAlign.Center,
  );

  static final tableHeaderStyle = excel.CellStyle(
    backgroundColorHex: excel.ExcelColor.fromHexString("#FF262626"),
    fontColorHex: excel.ExcelColor.fromHexString("#FFFFFFFF"),
    bold: true,
    horizontalAlign: excel.HorizontalAlign.Center,
    verticalAlign: excel.VerticalAlign.Center,
    topBorder: _thinBorder(),
    bottomBorder: _thinBorder(),
    leftBorder: _thinBorder(),
    rightBorder: _thinBorder(),
  );

  // Style untuk data transaksi utama - HIGHLIGHTED
  static final transactionRowStyle = excel.CellStyle(
    backgroundColorHex: excel.ExcelColor.fromHexString("#FF0D5ADB"),
    fontColorHex: excel.ExcelColor.fromHexString("#FFFFFFFF"),
    verticalAlign: excel.VerticalAlign.Center,
    bold: true,
    topBorder: _thinBorder(),
    bottomBorder: _thinBorder(),
    leftBorder: _thinBorder(),
    rightBorder: _thinBorder(),
  );

  // Style untuk data transaksi utama - HIGHLIGHTED
  static final transactionRowTextCenterStyle = excel.CellStyle(
    backgroundColorHex: excel.ExcelColor.fromHexString("#FF0D5ADB"),
    fontColorHex: excel.ExcelColor.fromHexString("#FFFFFFFF"),
    bold: true,
    horizontalAlign: excel.HorizontalAlign.Center,
    verticalAlign: excel.VerticalAlign.Center,
    topBorder: _thinBorder(),
    bottomBorder: _thinBorder(),
    leftBorder: _thinBorder(),
    rightBorder: _thinBorder(),
  );

  // Style untuk angka di row transaksi utama
  static final transactionNumberStyle = excel.CellStyle(
    backgroundColorHex: excel.ExcelColor.fromHexString("#FF0D5ADB"),
    fontColorHex: excel.ExcelColor.fromHexString("#FFFFFFFF"),
    bold: true,
    numberFormat: excel.CustomNumericNumFormat(formatCode: "#,##0"),
    horizontalAlign: excel.HorizontalAlign.Right,
    verticalAlign: excel.VerticalAlign.Center,
    topBorder: _thinBorder(),
    bottomBorder: _thinBorder(),
    leftBorder: _thinBorder(),
    rightBorder: _thinBorder(),
  );

  // Style untuk detail item header - SUBTLE
  static final detailItemHeaderStyle = excel.CellStyle(
    backgroundColorHex: excel.ExcelColor.fromHexString("#FFBFBFBF"),
    fontColorHex: excel.ExcelColor.fromHexString("#FF000000"),
    bold: true,
    italic: true,
    verticalAlign: excel.VerticalAlign.Center,
    topBorder: _thinBorder(),
    bottomBorder: _thinBorder(),
    leftBorder: _thinBorder(),
    rightBorder: _thinBorder(),
  );

  // Style untuk header tabel detail item
  static final detailTableHeaderStyle = excel.CellStyle(
    backgroundColorHex: excel.ExcelColor.fromHexString("#FFD9D9D9"),
    fontColorHex: excel.ExcelColor.fromHexString("#FF000000"),
    bold: true,
    horizontalAlign: excel.HorizontalAlign.Center,
    verticalAlign: excel.VerticalAlign.Center,
    topBorder: _thinBorder(),
    bottomBorder: _thinBorder(),
    leftBorder: _thinBorder(),
    rightBorder: _thinBorder(),
  );

  // Style untuk detail item - VERY SUBTLE
  static final detailItemRowStyle = excel.CellStyle(
    backgroundColorHex: excel.ExcelColor.fromHexString("#FFFFFFFF"),
    fontColorHex: excel.ExcelColor.fromHexString("#FF000000"),
    verticalAlign: excel.VerticalAlign.Center,
    topBorder: _thinBorder(),
    bottomBorder: _thinBorder(),
    leftBorder: _thinBorder(),
    rightBorder: _thinBorder(),
  );

  // Style untuk angka di detail item
  static final detailItemNumberStyle = excel.CellStyle(
    backgroundColorHex: excel.ExcelColor.fromHexString("#FFFFFFFF"),
    fontColorHex: excel.ExcelColor.fromHexString("#FF000000"),
    numberFormat: excel.CustomNumericNumFormat(formatCode: "#,##0"),
    horizontalAlign: excel.HorizontalAlign.Right,
    verticalAlign: excel.VerticalAlign.Center,
    topBorder: _thinBorder(),
    bottomBorder: _thinBorder(),
    leftBorder: _thinBorder(),
    rightBorder: _thinBorder(),
  );

  static final detailItemQtyStyle = excel.CellStyle(
    backgroundColorHex: excel.ExcelColor.fromHexString("#FFFFFFFF"),
    fontColorHex: excel.ExcelColor.fromHexString("#FF000000"),
    numberFormat: excel.CustomNumericNumFormat(formatCode: "#,##0"),
    horizontalAlign: excel.HorizontalAlign.Center,
    verticalAlign: excel.VerticalAlign.Center,
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
    // Judul - Row 1
    sheet.merge(excel.CellIndex.indexByString("A1"),
        excel.CellIndex.indexByString("H1"));
    sheet.cell(excel.CellIndex.indexByString("A1"))
      ..value = excel.TextCellValue(title)
      ..cellStyle = titleStyle;

    // SET HEIGHT UNTUK ROW TITLE
    sheet.setRowHeight(0, _titleRowHeight);

    // Periode - Row 2
    if (startDate != null && endDate != null) {
      final dateRange =
          'Periode: ${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}';
      sheet.merge(excel.CellIndex.indexByString("A2"),
          excel.CellIndex.indexByString("H2"));
      sheet.cell(excel.CellIndex.indexByString("A2"))
        ..value = excel.TextCellValue(dateRange)
        ..cellStyle = periodStyle;

      // SET HEIGHT UNTUK ROW PERIODE
      sheet.setRowHeight(1, _headerRowHeight);
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
      'Metode Pembayaran',
      'Added By'
    ];

    final headerRow = (startDate != null && endDate != null) ? 2 : 1;

    sheet
      ..setColumnWidth(0, 5)
      ..setColumnWidth(1, 23)
      ..setColumnWidth(2, 25)
      ..setColumnWidth(3, 18)
      ..setColumnWidth(4, 15)
      ..setColumnWidth(5, 15)
      ..setColumnWidth(6, 22)
      ..setColumnWidth(7, 20);

    for (int col = 0; col < headers.length; col++) {
      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: col, rowIndex: headerRow))
        ..value = excel.TextCellValue(headers[col])
        ..cellStyle = tableHeaderStyle;
    }

    // SET HEIGHT UNTUK HEADER ROW
    sheet.setRowHeight(headerRow, _headerRowHeight);
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

      // Main transaction row - HIGHLIGHTED
      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 0, rowIndex: currentRow))
        ..value = excel.IntCellValue(i + 1)
        ..cellStyle = transactionRowTextCenterStyle;

      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 1, rowIndex: currentRow))
        ..value = excel.TextCellValue(
            DateFormat('dd MMM yyyy HH:mm:ss').format(transaction.createdAt))
        ..cellStyle = transactionRowStyle;

      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 2, rowIndex: currentRow))
        ..value = excel.TextCellValue(item.customerName)
        ..cellStyle = transactionRowStyle;

      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 3, rowIndex: currentRow))
        ..value = excel.TextCellValue(item.customerPhone)
        ..cellStyle = transactionRowTextCenterStyle;

      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 4, rowIndex: currentRow))
        ..value = excel.TextCellValue(_formatPrice(transaction.discountPrice))
        ..cellStyle = transactionNumberStyle;

      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 5, rowIndex: currentRow))
        ..value = excel.TextCellValue(_formatPrice(transaction.finalPrice))
        ..cellStyle = transactionNumberStyle;

      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 6, rowIndex: currentRow))
        ..value = excel.TextCellValue(
          transaction.paymentMethod == 'qris'
              ? transaction.paymentMethod.toUpperCase()
              : toBeginningOfSentenceCase(transaction.paymentMethod),
        )
        ..cellStyle = transactionRowTextCenterStyle;

      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 7, rowIndex: currentRow))
        ..value = excel.TextCellValue(item.addedBy)
        ..cellStyle = transactionRowTextCenterStyle;

      // SET HEIGHT UNTUK ROW TRANSAKSI UTAMA
      sheet.setRowHeight(currentRow, _transactionRowHeight);

      // DETAIL ITEM - SUBTLE
      final items = await _transactionRepo.getTransactionItems(transaction.id);

      if (items.isNotEmpty) {
        currentRow++;
        _addItemSectionHeader(sheet, currentRow);
        // SET HEIGHT UNTUK SECTION HEADER
        sheet.setRowHeight(currentRow, _detailRowHeight);

        currentRow++;
        _addItemTableHeader(sheet, currentRow);
        // SET HEIGHT UNTUK HEADER DETAIL
        sheet.setRowHeight(currentRow, _detailRowHeight);

        for (final item in items) {
          currentRow++;
          final itemDetails =
              await _transactionRepo.getItemDetails(item.masterDataId);

          sheet.cell(excel.CellIndex.indexByColumnRow(
              columnIndex: 1, rowIndex: currentRow))
            ..value = excel.TextCellValue(itemDetails['name'] ?? 'Unknown Item')
            ..cellStyle = detailItemRowStyle;

          sheet.cell(excel.CellIndex.indexByColumnRow(
              columnIndex: 2, rowIndex: currentRow))
            ..value = excel.IntCellValue(item.qty)
            ..cellStyle = detailItemQtyStyle;

          sheet.cell(excel.CellIndex.indexByColumnRow(
              columnIndex: 3, rowIndex: currentRow))
            ..value = excel.TextCellValue(_formatPrice(itemDetails['price']))
            ..cellStyle = detailItemNumberStyle;

          sheet.cell(excel.CellIndex.indexByColumnRow(
              columnIndex: 4, rowIndex: currentRow))
            ..value = excel.TextCellValue(_formatPrice(item.totalPrice))
            ..cellStyle = detailItemNumberStyle;

          // SET HEIGHT UNTUK ROW DETAIL ITEM
          sheet.setRowHeight(currentRow, _detailRowHeight);
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
      excel.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row),
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
      '',
      ''
    ];
    for (int col = 0; col < headers.length; col++) {
      sheet.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        ..value = excel.TextCellValue(headers[col])
        ..cellStyle = detailTableHeaderStyle;
    }
  }

  /// Simpan file
  static Future<void> _saveAndExportFile(
      excel.Excel workbook, BuildContext context, String fileName) async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    final bytes = workbook.save();
    if (bytes == null) return;

    await file.writeAsBytes(bytes);

    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan Laporan',
      fileName: '$fileName.xlsx',
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
