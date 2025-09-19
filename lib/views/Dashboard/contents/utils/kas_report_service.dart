import 'dart:io';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meko_poin/models/additional/kas_with_balance.dart';
import 'package:path_provider/path_provider.dart';

class KasReportService {
  static const double _titleRowHeight = 30.0;
  static const double _headerRowHeight = 22.0;
  static const double _dataRowHeight = 20.0;

  /// Export laporan kas ke file Excel
  static Future<void> exportKasReportToExcel({
    required List<KasWithBalance> kasData,
    required String monthYear,
    required int finalBalance,
    required BuildContext context,
  }) async {
    try {
      final workbook = excel.Excel.createExcel();
      final sheetName = workbook.sheets.keys.first;
      final sheet = workbook[sheetName];

      _addReportHeader(sheet, monthYear);
      _addTableHeaders(sheet);
      _addKasData(sheet, kasData, finalBalance);

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

  /// Generate nama file
  static String _generateFileName(String monthYear) {
    return 'Laporan Kas $monthYear';
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

  static excel.CellStyle _createTypeStyle(String type) => excel.CellStyle(
        backgroundColorHex: excel.ExcelColor.fromHexString("#FFFFFFFF"),
        fontColorHex: excel.ExcelColor.fromHexString(
            type == 'income' ? "#FF00AA00" : "#FFFF0000"),
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
      ..value = excel.TextCellValue("Laporan Kas Bulanan")
      ..cellStyle = _createTitleStyle();

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

    sheet.setRowHeight(1, _headerRowHeight);
  }

  /// ===== HEADER TABLE =====
  static void _addTableHeaders(excel.Sheet sheet) {
    final headers = [
      'No',
      'Tanggal',
      'Jenis',
      'Nominal (Rp)',
      'Saldo Awal (Rp)',
      'Saldo Akhir (Rp)',
      'Keterangan'
    ];

    sheet
      ..setColumnWidth(0, 5) // No
      ..setColumnWidth(1, 20) // Tanggal
      ..setColumnWidth(2, 15) // Jenis
      ..setColumnWidth(3, 18) // Nominal
      ..setColumnWidth(4, 18) // Saldo Awal
      ..setColumnWidth(5, 18) // Saldo Akhir
      ..setColumnWidth(6, 60); // Keterangan

    for (int col = 0; col < headers.length; col++) {
      sheet
          .cell(excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 2))
        ..value = excel.TextCellValue(headers[col])
        ..cellStyle = _createTableHeaderStyle();
    }

    sheet.setRowHeight(2, _headerRowHeight);
  }

  /// ===== DATA KAS =====
  static void _addKasData(
    excel.Sheet sheet,
    List<KasWithBalance> kasData,
    int finalBalance,
  ) {
    int currentRow = 3;
    final currencyFormat = NumberFormat('#,###');

    for (int i = 0; i < kasData.length; i++) {
      final kasWithBalance = kasData[i];
      final kas = kasWithBalance.kas;

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
            excel.TextCellValue(DateFormat('dd MMMM yyyy').format(kas.cashDate))
        ..cellStyle = _createDataRowStyle();

      // Jenis
      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 2, rowIndex: currentRow))
        ..value = excel.TextCellValue(
            kas.type == 'income' ? 'Pemasukan' : 'Pengeluaran')
        ..cellStyle = _createTypeStyle(kas.type);

      // Nominal
      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 3, rowIndex: currentRow))
        ..value = excel.TextCellValue(currencyFormat.format(kas.amount))
        ..cellStyle = _createCurrencyStyle();

      // Saldo Awal
      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 4, rowIndex: currentRow))
        ..value = excel.TextCellValue(
            currencyFormat.format(kasWithBalance.initialBalance))
        ..cellStyle = _createCurrencyStyle();

      // Saldo Akhir
      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 5, rowIndex: currentRow))
        ..value = excel.TextCellValue(
            currencyFormat.format(kasWithBalance.finalBalance))
        ..cellStyle = _createCurrencyStyle();

      // Keterangan
      sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: 6, rowIndex: currentRow))
        ..value = excel.TextCellValue(kas.description)
        ..cellStyle = _createDataRowStyle();

      sheet.setRowHeight(currentRow, _dataRowHeight);
      currentRow++;
    }

    // Tambahkan row total
    _addTotalRow(sheet, currentRow, finalBalance, kasData);
  }

  /// Tambahkan row total
  static void _addTotalRow(excel.Sheet sheet, int row, int finalBalance,
      List<KasWithBalance> kasData) {
    final currencyFormat = NumberFormat('#,###');

    int totalPemasukan = kasData
        .where((k) => k.kas.type == 'income')
        .fold(0, (sum, k) => sum + k.kas.amount);

    int totalPengeluaran = kasData
        .where((k) => k.kas.type == 'outcome')
        .fold(0, (sum, k) => sum + k.kas.amount);

    int netCashFlow = totalPemasukan - totalPengeluaran;

    // Merge cells untuk label "TOTAL"
    sheet.merge(
      excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
    );

    sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
      ..value = excel.TextCellValue("Total Cash Flow (Rp)")
      ..cellStyle = _createTableHeaderStyle().copyWith(
        backgroundColorHexVal: excel.ExcelColor.fromHexString("#FF0D5ADB"),
      );

    sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
      ..value = excel.TextCellValue(currencyFormat.format(netCashFlow))
      ..cellStyle = _createTableHeaderStyle().copyWith(
        backgroundColorHexVal: excel.ExcelColor.fromHexString("#FF0D5ADB"),
        numberFormat: excel.CustomNumericNumFormat(formatCode: "#,##0"),
      );

    sheet.merge(
      excel.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
      excel.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row),
    );

    sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
      ..value = excel.TextCellValue("Saldo Akhir (Rp)")
      ..cellStyle = _createTableHeaderStyle().copyWith(
        backgroundColorHexVal: excel.ExcelColor.fromHexString("#FF0D5ADB"),
      );

    // Total Pemasukan
    // sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
    //   ..value = excel.TextCellValue(currencyFormat.format(totalPemasukan))
    //   ..cellStyle = _createTableHeaderStyle().copyWith(
    //     backgroundColorHexVal: excel.ExcelColor.fromHexString("#FF0D5ADB"),
    //     numberFormat: excel.CustomNumericNumFormat(formatCode: "#,##0"),
    //   );

    // Saldo Awal (kosong)
    // sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
    //   ..value = excel.TextCellValue("")
    //   ..cellStyle = _createTableHeaderStyle().copyWith(
    //     backgroundColorHexVal: excel.ExcelColor.fromHexString("#FF0D5ADB"),
    //   );

    // Saldo Akhir (net cash flow)
    sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
      ..value = excel.TextCellValue(currencyFormat.format(finalBalance))
      ..cellStyle = _createTableHeaderStyle().copyWith(
        backgroundColorHexVal: excel.ExcelColor.fromHexString("#FF0D5ADB"),
        numberFormat: excel.CustomNumericNumFormat(formatCode: "#,##0"),
      );

    // Keterangan
    // sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
    //   ..value = excel.TextCellValue("Net Cash Flow")
    //   ..cellStyle = _createTableHeaderStyle().copyWith(
    //     backgroundColorHexVal: excel.ExcelColor.fromHexString("#FF0D5ADB"),
    //   );

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
      dialogTitle: 'Simpan Laporan Kas',
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
          const SnackBar(content: Text('Laporan kas berhasil diekspor')),
        );
      }
    }
  }
}
