import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:rnd_mobile/widgets/toast.dart';

//Enable for WEB only
import 'dart:html' as html;

Future<void> generatePdf({
  required BuildContext context,
  required String title,
  required Map<String, dynamic> leftHeader,
  required Map<String, dynamic> rightHeader,
  required List<Map<String, dynamic>> lines,
  required List<Map<String, dynamic>> dataMap,
  required List<String> footer,
  bool small = false,
}) async {
  try {
    final pdf = pw.Document();

    Map<int, pw.TableColumnWidth> getPurchaseRequestColumnWidths() {
      return {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FixedColumnWidth(30),
        2: const pw.FixedColumnWidth(100),
        3: const pw.FixedColumnWidth(200),
        4: const pw.FixedColumnWidth(70),
      };
    }

    Map<int, pw.TableColumnWidth> getPurchaseOrderColumnWidths() {
      return {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FixedColumnWidth(200),
        2: const pw.FixedColumnWidth(50),
        3: const pw.FixedColumnWidth(30),
        4: const pw.FixedColumnWidth(50),
        5: const pw.FixedColumnWidth(50),
      };
    }

    Map<int, pw.TableColumnWidth> getSalesOrderColumnWidths() {
      return {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FixedColumnWidth(200),
        2: const pw.FixedColumnWidth(50),
        3: const pw.FixedColumnWidth(30),
        4: const pw.FixedColumnWidth(50),
        5: const pw.FixedColumnWidth(50),
      };
    }

    if (!small) {
      pdf.addPage(
        pw.MultiPage(
            build: (context) => [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Title
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 20.0),
                        child: pw.Center(
                          child: pw.Text(
                            title,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                      ),

                      // Headers
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: leftHeader.entries.map((entry) {
                                return pw.Row(
                                  children: [
                                    pw.SizedBox(
                                      width: 100,
                                      child: pw.Text('${entry.key}:'),
                                    ),
                                    pw.Text(
                                      ' ${entry.value}',
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.only(left: 70.0),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: rightHeader.entries.map((entry) {
                                  return pw.Row(
                                    children: [
                                      pw.SizedBox(
                                        width: 100,
                                        child: pw.Text('${entry.key}:'),
                                      ),
                                      pw.Text(
                                        ' ${entry.value}',
                                        style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 20),
                      pw.Divider(),

                      pw.Table(
                        columnWidths: title == 'PURCHASE REQUEST'
                            ? getPurchaseRequestColumnWidths()
                            : title == 'PURCHASE ORDER'
                                ? getPurchaseOrderColumnWidths()
                                : getSalesOrderColumnWidths(),
                        children: [
                          // Table headers
                          pw.TableRow(
                            children: lines
                                .map((line) => pw.Padding(
                                      padding:
                                          const pw.EdgeInsets.only(left: 5),
                                      child: pw.Text(line['name']),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                      pw.Divider(),

                      ...dataMap.map((row) {
                        return pw.Table(
                          columnWidths: title == 'PURCHASE REQUEST'
                              ? getPurchaseRequestColumnWidths()
                              : title == 'PURCHASE ORDER'
                                  ? getPurchaseOrderColumnWidths()
                                  : getSalesOrderColumnWidths(),
                          children: [
                            pw.TableRow(
                              children: lines
                                  .map((line) => pw.Padding(
                                        padding:
                                            const pw.EdgeInsets.only(left: 5),
                                        child: pw.Text(
                                            row[line['code']].toString()),
                                      ))
                                  .toList(),
                            ),
                          ],
                        );
                      }).toList(),

                      pw.SizedBox(height: 20),
                      pw.Center(
                        child: pw.Text(
                          ('*** NOTHING FOLLOWS ***'),
                          style: const pw.TextStyle(
                            fontSize: 15.0,
                          ),
                        ),
                      ),

                      pw.SizedBox(height: 5),
                      pw.Divider(),

                      if (title == "PURCHASE ORDER" ||
                          title == "SALES ORDER") ...[
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.SizedBox(
                              width: 100,
                              child: pw.Text(
                                'Total Amount:',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Text(
                              (dataMap.fold<num>(
                                      0,
                                      (previousValue, element) =>
                                          previousValue +
                                          (element['subtotal'] as num? ?? 0)))
                                  .toStringAsFixed(2),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                      pw.SizedBox(height: 15),

                      pw.Row(
                        children: footer.map((footerItem) {
                          return pw.Expanded(
                            child: pw.Padding(
                              padding:
                                  const pw.EdgeInsets.symmetric(horizontal: 5),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(footerItem),
                                  pw.SizedBox(height: 20),
                                  pw.Divider(
                                    color: PdfColor.fromHex('000000'),
                                    thickness: 0.5,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    ],
                  ),
                ]),
      );
    } else {
      pdf.addPage(
        pw.MultiPage(
          pageFormat:
              PdfPageFormat(2.5 * PdfPageFormat.inch, PdfPageFormat.a4.height),
          build: (context) => [
            pw.Center(
              child: pw.Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                style: const pw.TextStyle(
                  fontSize: 10.0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (kIsWeb) {
      // For Flutter web
      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = '$title-${leftHeader.values.first}.pdf';
      html.document.body?.children.add(anchor);

      // trigger the download
      anchor.click();

      // cleanup
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      // For Flutter mobile
      final output = await getExternalStorageDirectory();
      final fileName = "$title-${leftHeader.values.first}.pdf";
      final file = File("${output?.path}/$fileName");
      print('output.path: ${output?.path}');
      await file.writeAsBytes(await pdf.save());
      showToastMessage('PDF Generated');

      // Show dialog to confirm opening the PDF
      if (context.mounted) {
        bool openPdf = await showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Open PDF?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Yes'),
                  onPressed: () {
                    Navigator.of(dialogContext)
                        .pop(true); // Return true to open PDF
                  },
                ),
                TextButton(
                  child: const Text('No'),
                  onPressed: () {
                    Navigator.of(dialogContext)
                        .pop(false); // Return false to not open PDF
                  },
                ),
              ],
            );
          },
        );

        if (openPdf == true) {
          showToastMessage('Opening PDF');
          await OpenFile.open(file.path);
        }
      }
    }
  } catch (e) {
    showToastMessage('Error generating PDF: $e');
    print('Error generating PDF: $e');
  }
}
