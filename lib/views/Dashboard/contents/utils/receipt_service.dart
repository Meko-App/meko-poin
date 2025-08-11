// receipt_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

class ReceiptService {
  static Future<Uint8List> generateReceiptPdf(
      Map<String, dynamic> transactionData) async {
    final pdf = pw.Document();

    final logoImage = await rootBundle.load('assets/logo-photorism-hitam.png');
    final logoImageBytes = logoImage.buffer.asUint8List();
    final logo = pw.MemoryImage(logoImageBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Image(
                  logo,
                  height: 40,
                  width: 120,
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                  child: pw.Text(
                      'Gg. Gandasoli I No.36A, RT.1/RW.6, Kab. Bandung',
                      style: pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),

              // Transaction Info
              pw.Text('No. Invoice: ${transactionData['invoice']}',
                  style: pw.TextStyle(fontSize: 10)),
              pw.Text('Tanggal: ${transactionData['date']}',
                  style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 8),

              // Customer Info
              pw.Text('Pelanggan: ${transactionData['name']}',
                  style: pw.TextStyle(fontSize: 10)),
              pw.Text('No. HP: ${transactionData['phone']}',
                  style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),

              // Items
              pw.Text('ITEMS',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ...(transactionData['cart_items'] as List).map((item) {
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(item['name'],
                          style: pw.TextStyle(fontSize: 10)),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(item['qty'].toString(),
                          style: pw.TextStyle(fontSize: 10)),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        _formatPrice(item['total_price'] ?? 0),
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                );
              }).toList(),
              pw.Divider(thickness: 1),

              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: pw.TextStyle(fontSize: 10)),
                  pw.Text(_formatPrice(transactionData['total_price']),
                      style: pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Diskon:', style: pw.TextStyle(fontSize: 10)),
                  pw.Text(_formatPrice(transactionData['discount_price']),
                      style: pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(_formatPrice(transactionData['final_price']),
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text('Pembayaran: ${transactionData['payment_method']}',
                  style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 16),
              pw.Center(
                  child: pw.Text('Terima Kasih Telah Berkunjung',
                      style: pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 4),
              pw.Center(
                  child: pw.Text('IG: @photorismstudio',
                      style: pw.TextStyle(fontSize: 10))),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printReceipt(Map<String, dynamic> transactionData) async {
    final pdf = await generateReceiptPdf(transactionData);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf,
    );
  }

  static Future<void> saveReceiptPdf(
    Map<String, dynamic> transactionData,
    BuildContext context, // <--- Pass BuildContext here if you want SnackBar
  ) async {
    try {
      // 1. Generate the PDF bytes
      final pdfBytes = await generateReceiptPdf(transactionData);

      // 2. Create a temporary file to hold the PDF bytes
      //    file_picker often works best by picking a destination for an existing file.
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/${transactionData['invoice']}.pdf';
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(pdfBytes);

      // 3. Open the file picker for saving
      final String? selectedDirectory = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Struk PDF',
        fileName: '${transactionData['invoice']}.pdf',
        // By default, it suggests a name. If the user picks a folder,
        // it combines the chosen folder with this fileName.
        type: FileType.custom,
        allowedExtensions: ['pdf'], // Filter for PDF files
      );

      // 4. Handle the user's selection
      if (selectedDirectory != null) {
        // User selected a directory and confirmed save
        final File newFile = File(selectedDirectory);

        // Copy the temporary file content to the new location
        await tempFile.copy(newFile.path);

        // Clean up the temporary file
        await tempFile.delete();

        // Show SnackBar (requires valid context)
        if (context != null) {
          // Only show if context is provided and valid
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Struk disimpan di: ${newFile.path}')),
          );
        }
        print('Struk disimpan di: ${newFile.path}');
      } else {
        // User cancelled the file picker
        print('Penyimpanan struk dibatalkan.');
        await tempFile.delete(); // Clean up temporary file
      }
    } catch (e) {
      print('Error saving PDF: $e');
      if (context != null) {
        // Show an error SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan struk: $e')),
        );
      }
    }
  }

  static Future<void> shareReceipt(
      Map<String, dynamic> transactionData, String phone) async {
    final pdf = await generateReceiptPdf(transactionData);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${transactionData['invoice']}.pdf');
    await file.writeAsBytes(pdf);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Struk pembelian dari MEKO POIN',
      subject: 'Struk ${transactionData['invoice']}',
      sharePositionOrigin: Rect.zero,
    );
  }
}

String _formatPrice(int price) {
  final formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  return formatter.format(price);
}
