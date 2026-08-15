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
import 'package:url_launcher/url_launcher.dart';

class ReceiptService {
  static Future<Uint8List> generateReceiptPdf(
      Map<String, dynamic> transactionData) async {
    final pdf = pw.Document();

    final logoImage = await rootBundle.load('assets/logo-photorism-hitam.png');
    final logoImageBytes = logoImage.buffer.asUint8List();
    final logo = pw.MemoryImage(logoImageBytes);

    final instagramIconImage =
        await rootBundle.load('assets/instagram-icon.png');
    final instagramIconBytes = instagramIconImage.buffer.asUint8List();
    final instagramIcon = pw.MemoryImage(instagramIconBytes);

    final tiktokIconImage = await rootBundle.load('assets/tiktok-icon.png');
    final tiktokIconBytes = tiktokIconImage.buffer.asUint8List();
    final tiktokIcon = pw.MemoryImage(tiktokIconBytes);

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
              pw.Text(
                'Gg. Gandasoli I No.36A, RT.1/RW.6, Kab. Bandung',
                style: pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),

              // Transaction Info
              pw.Text('No. Invoice: ${transactionData['invoice']}',
                  style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 2),
              pw.Text('Tanggal: ${transactionData['date']}',
                  style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 8),

              // Customer Info
              pw.Text('Pelanggan: ${transactionData['name']}',
                  style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 2),
              pw.Text('No. HP: ${transactionData['phone']}',
                  style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),

              // Items
              // pw.Text('ITEMS',
              //     style: pw.TextStyle(
              //         fontWeight: pw.FontWeight.bold, fontSize: 10)),
              // ...((transactionData['cart_items'] as List).where((item) {
              //   final category =
              //       item['category']?.toString().toLowerCase() ?? '';
              //   return category == 'product' ||
              //       category == 'paper' ||
              //       category == 'additional';
              // }).map((item) {
              //   return pw.Row(
              //     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              //     children: [
              //       pw.Expanded(
              //         flex: 3,
              //         child: pw.Text(item['name'],
              //             style: pw.TextStyle(fontSize: 10)),
              //       ),
              //       pw.Expanded(
              //         flex: 1,
              //         child: pw.Text(item['qty'].toString(),
              //             style: pw.TextStyle(fontSize: 10)),
              //       ),
              //       pw.Expanded(
              //         flex: 2,
              //         child: pw.Text(
              //           _formatPrice(item['total_price'] ?? 0),
              //           style: pw.TextStyle(fontSize: 10),
              //           textAlign: pw.TextAlign.right,
              //         ),
              //       ),
              //     ],
              //   );
              // }).toList()),

              pw.Text('ITEMS',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.SizedBox(height: 4),
              ...(transactionData['cart_items'] as List).expand((item) {
                final bundleComponents =
                    item['bundle_components'] as List? ?? [];
                final widgets = <pw.Widget>[
                  pw.Row(
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
                  ),
                ];
                for (final component in bundleComponents) {
                  final bundleQty = (item['qty'] as num?)?.toInt() ?? 1;
                  final componentQty =
                      (component['qty'] as num?)?.toInt() ?? 1;
                  final totalComponentQty = bundleQty * componentQty;
                  widgets.add(
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 8),
                      child: pw.Text(
                        '- ${component['component_name']} (x$totalComponentQty)',
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  );
                }
                return widgets;
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
              pw.Text(
                  'Pembayaran: ${transactionData['payment_method'] == 'cash' ? 'Cash' : transactionData['payment_method'] == 'qris' ? 'QRIS' : transactionData['payment_method']}',
                  style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 16),
              pw.Center(
                  child: pw.Text('Terima Kasih Telah Berkunjung',
                      style: pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 4),
              // Instagram dengan icon
              pw.Center(
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Image(
                      tiktokIcon,
                      height: 14,
                      width: 14,
                      fit: pw.BoxFit.contain,
                    ),
                    pw.SizedBox(width: 4),
                    pw.Image(
                      instagramIcon,
                      height: 12,
                      width: 12,
                      fit: pw.BoxFit.contain,
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text('@photorismstudio',
                        style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
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
    BuildContext? context,
  ) async {
    try {
      final pdfBytes = await generateReceiptPdf(transactionData);
      final tempDir = await getTemporaryDirectory();
      final tempFile =
          File('${tempDir.path}/${transactionData['invoice']}.pdf');
      await tempFile.writeAsBytes(pdfBytes);

      final String? savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Struk PDF',
        fileName: '${transactionData['invoice']}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (savedPath != null) {
        await tempFile.copy(savedPath);
        await tempFile.delete();

        // Tampilkan SnackBar HANYA jika context valid dan mounted
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Struk disimpan di: $savedPath')),
          );
        }
      } else {
        await tempFile.delete();
      }
    } catch (e) {
      // Error handling dengan cek context
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan struk: $e')),
        );
      }
      rethrow; // Optional: Lempar kembali error untuk handling tambahan
    }
  }

  static Future<void> shareReceipt(
      Map<String, dynamic> transactionData, String phone) async {
    final pdf = await generateReceiptPdf(transactionData);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${transactionData['invoice']}.pdf');
    await file.writeAsBytes(pdf);

    final strukText = _buildStrukText(transactionData);

    if (phone.isNotEmpty) {
      String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.startsWith('0')) {
        cleanPhone = '62${cleanPhone.substring(1)}';
      }

      final whatsappUrl = Uri.parse(
          'whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(strukText)}');
      final webUrl = Uri.parse(
          'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(strukText)}');

      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: strukText,
          subject: 'Struk ${transactionData['invoice']}',
          sharePositionOrigin: Rect.zero,
        );
      }
    } else {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: strukText,
        subject: 'Struk ${transactionData['invoice']}',
        sharePositionOrigin: Rect.zero,
      );
    }
  }
}

String _buildStrukText(Map<String, dynamic> transactionData) {
  final buffer = StringBuffer();

  buffer.writeln('Struk Photorism Studio');
  buffer.writeln();
  buffer.writeln('*Invoice:* ${transactionData['invoice']}');
  buffer.writeln('*Tanggal:* ${transactionData['date']}');
  buffer.writeln('*Pelanggan:* ${transactionData['name']}');
  buffer.writeln();
  buffer.writeln('*Detail Pesanan:*');

  for (final item in (transactionData['cart_items'] as List? ?? [])) {
    final name = item['name'];
    final qty = item['qty'];
    final totalPrice = item['total_price'] ?? 0;
    buffer.writeln('* $name (Qty: $qty) - ${_formatPrice(totalPrice)}');
  }

  buffer.writeln();
  buffer.writeln('*Subtotal:* ${_formatPrice(transactionData['total_price'])}');
  buffer.writeln('*Diskon:* ${_formatPrice(transactionData['discount_price'])}');
  buffer.writeln('*Total:* ${_formatPrice(transactionData['final_price'])}');
  buffer.writeln();
  buffer.writeln(
      '*Metode Pembayaran:* ${transactionData['payment_method'] == 'cash' ? 'Cash' : transactionData['payment_method'] == 'qris' ? 'QRIS' : transactionData['payment_method']}');
  buffer.writeln();
  buffer.writeln('Terima kasih telah berkunjung di Photorism Studio!');

  return buffer.toString();
}

String _formatPrice(int price) {
  final formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  return formatter.format(price);
}
