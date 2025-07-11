import 'package:excel/excel.dart' as excel;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class ReportService {
  static Future<void> exportTransactionsToExcel({
    required List<dynamic> transactions,
    required String reportTitle,
    DateTime? startDate,
    DateTime? endDate,
    required BuildContext context,
  }) async {
    try {
      // 1. Create Excel workbook
      final excel.Excel excelWorkbook = excel.Excel.createExcel();
      final excel.Sheet sheet = excelWorkbook['Laporan Penjualan'];

      // 2. Add title and date range
      final title = reportTitle;

      // Title row
      sheet.merge(excel.CellIndex.indexByString("A1"),
          excel.CellIndex.indexByString("G1"));
      sheet.cell(excel.CellIndex.indexByString("A1"))
        ..value = excel.TextCellValue(title)
        ..cellStyle = excel.CellStyle(
          bold: true,
          fontSize: 20,
          horizontalAlign: excel.HorizontalAlign.Center,
          verticalAlign: excel.VerticalAlign.Center,
        );

      // Date range row (only if dates are provided)
      if (startDate != null && endDate != null) {
        final dateRange =
            'Periode: ${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}';
        sheet.merge(excel.CellIndex.indexByString("A2"),
            excel.CellIndex.indexByString("G2"));
        sheet.cell(excel.CellIndex.indexByString("A2"))
          ..value = excel.TextCellValue(dateRange)
          ..cellStyle = excel.CellStyle(
            fontSize: 14,
            horizontalAlign: excel.HorizontalAlign.Center,
            verticalAlign: excel.VerticalAlign.Center,
          );
      }

      // 3. Define border styles
      final excel.Border thinBorder = excel.Border(
        borderStyle: excel.BorderStyle.Thin,
        borderColorHex: excel.ExcelColor.fromHexString("#FF000000"),
      );

      final excel.CellStyle headerStyle = excel.CellStyle(
        backgroundColorHex: excel.ExcelColor.fromHexString("#FFD3D3D3"),
        bold: true,
        horizontalAlign: excel.HorizontalAlign.Center,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
      );

      // 4. Add headers (starting from row 3 if dates are shown, otherwise row 2)
      final headerRow = (startDate != null && endDate != null) ? 2 : 1;
      final dataStartRow = headerRow + 1;

      final headers = [
        'No',
        'Tanggal',
        'Nama Pelanggan',
        'No HP Pelanggan',
        'Diskon (Rp)',
        'Total (Rp)',
        'Added By'
      ];

      // Set column widths (in characters)
      // The excel package uses this method to set column width
      sheet.setColumnWidth(0, 5); // No
      sheet.setColumnWidth(1, 12); // Tanggal
      sheet.setColumnWidth(2, 25); // Nama Pelanggan
      sheet.setColumnWidth(3, 18); // No HP Pelanggan
      sheet.setColumnWidth(4, 15); // Diskon (Rp)
      sheet.setColumnWidth(5, 15); // Total (Rp)
      sheet.setColumnWidth(6, 20); // Added By

      for (int col = 0; col < headers.length; col++) {
        sheet.cell(excel.CellIndex.indexByColumnRow(
            columnIndex: col, rowIndex: headerRow))
          ..value = excel.TextCellValue(headers[col])
          ..cellStyle = headerStyle;
      }

      // 5. Add data rows
      final excel.CellStyle dataStyle = excel.CellStyle(
        topBorder: thinBorder,
        bottomBorder: thinBorder,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
      );

      final excel.CellStyle numberStyle = excel.CellStyle(
        numberFormat: excel.CustomNumericNumFormat(formatCode: "#,##0"),
        horizontalAlign: excel.HorizontalAlign.Right,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
      );

      for (int i = 0; i < transactions.length; i++) {
        final rowIndex = i + dataStartRow;
        final item = transactions[i];
        final transaction = item.transaction;

        // Add data cells with proper styling
        sheet.cell(excel.CellIndex.indexByColumnRow(
            columnIndex: 0, rowIndex: rowIndex))
          ..value = excel.IntCellValue(i + 1)
          ..cellStyle = dataStyle;

        sheet.cell(excel.CellIndex.indexByColumnRow(
            columnIndex: 1, rowIndex: rowIndex))
          ..value = excel.TextCellValue(
              DateFormat('dd/MM/yyyy').format(transaction.createdAt))
          ..cellStyle = dataStyle;

        sheet.cell(excel.CellIndex.indexByColumnRow(
            columnIndex: 2, rowIndex: rowIndex))
          ..value = excel.TextCellValue(item.customerName)
          ..cellStyle = dataStyle;

        sheet.cell(excel.CellIndex.indexByColumnRow(
            columnIndex: 3, rowIndex: rowIndex))
          ..value = excel.TextCellValue(item.customerPhone)
          ..cellStyle = dataStyle;

        sheet.cell(excel.CellIndex.indexByColumnRow(
            columnIndex: 4, rowIndex: rowIndex))
          ..value = excel.TextCellValue(_formatPrice(transaction.discountPrice))
          ..cellStyle = numberStyle;

        sheet.cell(excel.CellIndex.indexByColumnRow(
            columnIndex: 5, rowIndex: rowIndex))
          ..value = excel.TextCellValue(_formatPrice(transaction.finalPrice))
          ..cellStyle = numberStyle;

        sheet.cell(excel.CellIndex.indexByColumnRow(
            columnIndex: 6, rowIndex: rowIndex))
          ..value = excel.TextCellValue(item.addedBy)
          ..cellStyle = dataStyle;
      }

      // 6. Save and export file
      final directory = await getTemporaryDirectory();
      final fileName =
          'Laporan_Penjualan_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      final bytes = excelWorkbook.save();

      if (bytes != null) {
        await file.writeAsBytes(bytes);

        // Ensure the file name includes .xlsx extension
        final saveFileName =
            fileName.endsWith('.xlsx') ? fileName : '$fileName.xlsx';

        final savedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Simpan Laporan',
          fileName: saveFileName,
          allowedExtensions: ['xlsx'],
          type: FileType.custom,
        );

        if (savedPath != null) {
          // Ensure the saved path has the correct extension
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}

String _formatPrice(int price) {
  final formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
  return formatter.format(price);
}
