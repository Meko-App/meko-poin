import 'dart:io';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meko_poin/models/additional/daily_report.dart';
import 'package:path_provider/path_provider.dart';

extension StringCaseExtension on String {
  String toAllCaps() {
    return toUpperCase();
  }

  String toSentenceCase() {
    return toBeginningOfSentenceCase(this) ?? this;
  }
}

class DailyReportExportService {
  // TAMBAHKAN CONSTANT UNTUK ROW HEIGHT
  static const double _titleRowHeight = 30.0;
  static const double _headerRowHeight = 22.0;
  static const double _dataRowHeight = 20.0;

  /// Export laporan harian ke file Excel
  static Future<void> exportDailyReportsToExcel({
    required List<DailyReport> dailyReports,
    required String monthYear,
    required BuildContext context,
  }) async {
    try {
      final workbook = excel.Excel.createExcel();
      final sheetName = workbook.sheets.keys.first;
      final sheet = workbook[sheetName];

      _addReportHeader(sheet, monthYear);
      _addTableHeaders(sheet);
      _addDailyReportData(sheet, dailyReports);

      final fileName = _generateFileName(monthYear);

      await _saveAndExportFile(workbook, context, fileName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  /// GENERATE FILE NAME BERDASARKAN BULAN DAN TAHUN
  static String _generateFileName(String monthYear) {
    return 'Laporan Penjualan Bulanan $monthYear';
  }

  /// ===== STYLE SECTION =====
  static excel.Border _thinBorder() => excel.Border(
        borderStyle: excel.BorderStyle.Thin,
        borderColorHex: excel.ExcelColor.fromHexString("#FF000000"),
      );

  static excel.CellStyle _createTitleStyle() => excel.CellStyle(
        bold: true,
        fontSize: 20,
        backgroundColorHex: excel.ExcelColor.fromHexString("#FFB3CEFB"),
        fontColorHex: excel.ExcelColor.fromHexString("#FF000000"),
        horizontalAlign: excel.HorizontalAlign.Center,
        verticalAlign: excel.VerticalAlign.Center,
      );

  static excel.CellStyle _createTableHeaderStyle() => excel.CellStyle(
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

  static excel.CellStyle _createDataRowStyle() => excel.CellStyle(
        backgroundColorHex: excel.ExcelColor.fromHexString("#FFFFFFFF"),
        fontColorHex: excel.ExcelColor.fromHexString("#FF000000"),
        verticalAlign: excel.VerticalAlign.Center,
        topBorder: _thinBorder(),
        bottomBorder: _thinBorder(),
        leftBorder: _thinBorder(),
        rightBorder: _thinBorder(),
      );

  static excel.CellStyle _createDataNumberStyle() => excel.CellStyle(
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

  static excel.CellStyle _createCurrencyStyle() => excel.CellStyle(
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

  /// ===== HEADER REPORT =====
  static void _addReportHeader(excel.Sheet sheet, String monthYear) {
    // Judul - Row 1
    sheet.merge(excel.CellIndex.indexByString("A1"),
        excel.CellIndex.indexByString("G1"));
    sheet.cell(excel.CellIndex.indexByString("A1"))
      ..value = excel.TextCellValue("Catatan Penjualan Bulanan")
      ..cellStyle = _createTitleStyle();

    // SET HEIGHT UNTUK ROW TITLE
    sheet.setRowHeight(0, _titleRowHeight);

    // Periode - Row 2
    sheet.merge(excel.CellIndex.indexByString("A2"),
        excel.CellIndex.indexByString("G2"));
    sheet.cell(excel.CellIndex.indexByString("A2"))
      ..value = excel.TextCellValue("Bulan: $monthYear")
      ..cellStyle = _createTableHeaderStyle().copyWith(
        backgroundColorHexVal: excel.ExcelColor.fromHexString("#FF444444"),
        fontSizeVal: 14,
      );

    // SET HEIGHT UNTUK ROW PERIODE
    sheet.setRowHeight(1, _headerRowHeight);
  }

  /// ===== HEADER TABLE =====
  static void _addTableHeaders(excel.Sheet sheet) {
    final headers = [
      'No',
      'Tanggal',
      'Jumlah Pelanggan',
      'Total (Rp)',
      'Total Tunai (Rp)',
      'Total QRIS (Rp)',
      'Penjualan (Rp)'
    ];

    sheet
      ..setColumnWidth(0, 5) // No
      ..setColumnWidth(1, 20) // Tanggal
      ..setColumnWidth(2, 18) // Jumlah Pelanggan
      ..setColumnWidth(3, 18) // Total Pendapatan
      ..setColumnWidth(4, 20) // Total Tunai
      ..setColumnWidth(5, 20) // Total QRIS
      ..setColumnWidth(6, 20); // Total Penjualan

    for (int col = 0; col < headers.length; col++) {
      sheet
          .cell(excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 2))
        ..value = excel.TextCellValue(headers[col])
        ..cellStyle = _createTableHeaderStyle();
    }

    // SET HEIGHT UNTUK HEADER ROW
    sheet.setRowHeight(2, _headerRowHeight);
  }

  /// ===== DATA LAPORAN HARIAN =====
  static void _addDailyReportData(
    excel.Sheet sheet,
    List<DailyReport> dailyReports,
  ) {
    int currentRow = 3;
    final currencyFormat = NumberFormat('#,###');

    for (int i = 0; i < dailyReports.length; i++) {
      final report = dailyReports[i];

      // No
      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 0, rowIndex: currentRow))
        ..value = excel.IntCellValue(i + 1)
        ..cellStyle = _createDataRowStyle()
            .copyWith(horizontalAlignVal: excel.HorizontalAlign.Center);

      // Tanggal
      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 1, rowIndex: currentRow))
        ..value =
            excel.TextCellValue(DateFormat('d MMMM yyyy').format(report.date))
        ..cellStyle = _createDataRowStyle();

      // Jumlah Pelanggan
      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 2, rowIndex: currentRow))
        ..value = excel.IntCellValue(report.totalSales.toInt())
        ..cellStyle = _createDataNumberStyle();

      // Total Pendapatan
      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 3, rowIndex: currentRow))
        ..value =
            excel.TextCellValue(currencyFormat.format(report.totalRevenue))
        ..cellStyle = _createCurrencyStyle();

      // Total Tunai
      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 4, rowIndex: currentRow))
        ..value = excel.TextCellValue(currencyFormat.format(report.totalCash))
        ..cellStyle = _createCurrencyStyle();

      // Total QRIS
      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 5, rowIndex: currentRow))
        ..value = excel.TextCellValue(currencyFormat.format(report.totalQris))
        ..cellStyle = _createCurrencyStyle();

      // Total Penjualan
      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 6, rowIndex: currentRow))
        ..value =
            excel.TextCellValue(currencyFormat.format(report.totalRevenue))
        ..cellStyle = _createCurrencyStyle();

      // SET HEIGHT UNTUK ROW DATA
      sheet.setRowHeight(currentRow, _dataRowHeight);
      currentRow++;
    }

    // Tambahkan row total
    _addTotalRow(sheet, currentRow, dailyReports);
  }

  /// Tambahkan row total
  static void _addTotalRow(
      excel.Sheet sheet, int row, List<DailyReport> dailyReports) {
    final currencyFormat = NumberFormat('#,###');

    int totalCustomers =
        dailyReports.fold(0, (sum, report) => sum + report.totalSales.toInt());
    int totalRevenue = dailyReports.fold(
        0, (sum, report) => sum + report.totalRevenue.toInt());
    int totalCash =
        dailyReports.fold(0, (sum, report) => sum + report.totalCash.toInt());
    int totalQris =
        dailyReports.fold(0, (sum, report) => sum + report.totalQris.toInt());
    int totalSales = dailyReports.fold(
        0, (sum, report) => sum + report.totalRevenue.toInt());

    // Merge cells untuk label "TOTAL"
    sheet.merge(
      excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
    );

    sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = excel.TextCellValue("TOTAL")
      ..cellStyle = _createTableHeaderStyle().copyWith(
        backgroundColorHexVal: excel.ExcelColor.fromHexString("#FF0D5ADB"),
      );

    // Jumlah Pelanggan
    sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
      ..value = excel.IntCellValue(totalCustomers)
      ..cellStyle = _createTableHeaderStyle().copyWith(
        backgroundColorHexVal: excel.ExcelColor.fromHexString("#FF0D5ADB"),
        numberFormat: excel.CustomNumericNumFormat(formatCode: "#,##0"),
      );

    // Total Pendapatan
    sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
      ..value = excel.TextCellValue(currencyFormat.format(totalRevenue))
      ..cellStyle = _createTableHeaderStyle().copyWith(
        backgroundColorHexVal: excel.ExcelColor.fromHexString("#FF0D5ADB"),
        numberFormat: excel.CustomNumericNumFormat(formatCode: "#,##0"),
      );

    // Total Tunai
    sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
      ..value = excel.TextCellValue(currencyFormat.format(totalCash))
      ..cellStyle = _createTableHeaderStyle().copyWith(
        backgroundColorHexVal: excel.ExcelColor.fromHexString("#FF0D5ADB"),
        numberFormat: excel.CustomNumericNumFormat(formatCode: "#,##0"),
      );

    // Total QRIS
    sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
      ..value = excel.TextCellValue(currencyFormat.format(totalQris))
      ..cellStyle = _createTableHeaderStyle().copyWith(
        backgroundColorHexVal: excel.ExcelColor.fromHexString("#FF0D5ADB"),
        numberFormat: excel.CustomNumericNumFormat(formatCode: "#,##0"),
      );

    // Total Penjualan
    sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
      ..value = excel.IntCellValue(totalSales)
      ..cellStyle = _createTableHeaderStyle().copyWith(
        backgroundColorHexVal: excel.ExcelColor.fromHexString("#FF0D5ADB"),
        numberFormat: excel.CustomNumericNumFormat(formatCode: "#,##0"),
      );

    // SET HEIGHT UNTUK ROW TOTAL
    sheet.setRowHeight(row, _headerRowHeight);
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
}
