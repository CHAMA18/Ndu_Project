import 'dart:convert';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart' as loader;

class SsherExportHelper {
  static String entriesToCsv(
    List<SsherEntry> entries, {
    String? categoryTitle,
    List<WorkItem>? wbsItems,
    List<CostEstimateItem>? costItems,
  }) {
    final buffer = StringBuffer();

    // Header
    if (categoryTitle != null) {
      buffer.writeln('Category: $categoryTitle');
      buffer.writeln();
    }

    buffer.writeln(
      '#,Department,Team Member,Concern,Risk Level,Mitigation Strategy,Linked WBS,Linked Cost Item,Linked Schedule,Linked Requirement,Traceability Notes',
    );

    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      final row = [
        '${i + 1}',
        _escapeCsv(e.department),
        _escapeCsv(e.teamMember),
        _escapeCsv(e.concern),
        _escapeCsv(e.riskLevel),
        _escapeCsv(e.mitigation),
        _escapeCsv(_resolveWbsName(e.linkedWbsId, wbsItems)),
        _escapeCsv(_resolveCostItemName(e.linkedCostItemId, costItems)),
        _escapeCsv(e.linkedRequirementId),
        _escapeCsv(e.traceabilityNotes),
      ];
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  static String _resolveWbsName(String wbsId, List<WorkItem>? wbsItems) {
    if (wbsId.isEmpty || wbsItems == null) return '';
    for (final item in wbsItems) {
      if (item.id == wbsId) return item.title;
      final found = _findWbsInTree(item.children, wbsId);
      if (found != null) return found;
    }
    return wbsId;
  }

  static String? _findWbsInTree(List<WorkItem> children, String wbsId) {
    for (final child in children) {
      if (child.id == wbsId) return child.title;
      if (child.children.isNotEmpty) {
        final found = _findWbsInTree(child.children, wbsId);
        if (found != null) return found;
      }
    }
    return null;
  }

  static String _resolveCostItemName(
    String costItemId,
    List<CostEstimateItem>? costItems,
  ) {
    if (costItemId.isEmpty || costItems == null) return '';
    for (final item in costItems) {
      if (item.id == costItemId) return item.title;
    }
    return costItemId;
  }

  static String allEntriesToCsv(
    Map<String, List<SsherEntry>> categoryMap, {
    List<WorkItem>? wbsItems,
    List<CostEstimateItem>? costItems,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('SSHER Export - All Categories');
    buffer.writeln();

    categoryMap.forEach((category, entries) {
      buffer.writeln(entriesToCsv(
        entries,
        categoryTitle: category,
        wbsItems: wbsItems,
        costItems: costItems,
      ));
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    });

    return buffer.toString();
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static Future<void> downloadCsv(String csvContent, String filename) async {
    final bytes = utf8.encode(csvContent);
    loader.downloadFile(bytes, filename);
  }

  static Future<void> exportToPdf(
    List<SsherEntry> entries, {
    required String categoryTitle,
    List<WorkItem>? wbsItems,
    List<CostEstimateItem>? costItems,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('SSHER Export - $categoryTitle',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: [
              '#',
              'Department',
              'Team Member',
              'Concern',
              'Risk Level',
              'Mitigation Strategy',
              'Linked WBS',
              'Linked Cost Item',
              'Linked Requirement',
              'Traceability Notes',
            ],
            data: List<List<String>>.generate(
              entries.length,
              (index) => [
                '${index + 1}',
                entries[index].department,
                entries[index].teamMember,
                entries[index].concern,
                entries[index].riskLevel,
                entries[index].mitigation,
                _resolveWbsName(entries[index].linkedWbsId, wbsItems),
                _resolveCostItemName(
                    entries[index].linkedCostItemId, costItems),
                entries[index].linkedRequirementId,
                entries[index].traceabilityNotes,
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'ssher_${categoryTitle.toLowerCase()}.pdf',
    );
  }

  static Future<void> exportAllToPdf(
    Map<String, List<SsherEntry>> categoryMap, {
    List<WorkItem>? wbsItems,
    List<CostEstimateItem>? costItems,
  }) async {
    final doc = pw.Document();

    categoryMap.forEach((category, entries) {
      if (entries.isEmpty) return;
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('SSHER Export - $category',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: [
                '#',
                'Department',
                'Team Member',
                'Concern',
                'Risk Level',
                'Mitigation Strategy',
                'Linked WBS',
                'Linked Cost Item',
                'Linked Schedule',
                'Linked Requirement',
                'Traceability Notes',
              ],
              data: List<List<String>>.generate(
                entries.length,
                (index) => [
                  '${index + 1}',
                  entries[index].department,
                  entries[index].teamMember,
                  entries[index].concern,
                  entries[index].riskLevel,
                  entries[index].mitigation,
                  _resolveWbsName(entries[index].linkedWbsId, wbsItems),
                  _resolveCostItemName(
                      entries[index].linkedCostItemId, costItems),
                  entries[index].linkedRequirementId,
                  entries[index].traceabilityNotes,
                ],
              ),
            ),
          ],
        ),
      );
    });

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'ssher_all_categories.pdf',
    );
  }
}
