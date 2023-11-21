import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> generatePdf({
  required String title,
  required Map<String, dynamic> leftHeader,
  required Map<String, dynamic> rightHeader,
  required List<dynamic> lines,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (context) => pw.Column(
        children: [
          // Title
          pw.Text(title),

          // Headers
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(leftHeader.toString()),
              ),
              pw.Expanded(
                child: pw.Text(rightHeader.toString()),
              ),
            ],
          ),

          // Table
          pw.Table.fromTextArray(
            context: context,
            data: lines,
          ),
        ],
      ),
    ),
  );

  final output = await getApplicationDocumentsDirectory();
  final file = File("${output.path}/$title.pdf");
  await file.writeAsBytes(await pdf.save());
}
