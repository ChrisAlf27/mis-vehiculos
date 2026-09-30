import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_helper.dart';
import '../models/vehicle.dart';
import '../models/maintenance_type.dart';
import 'database_service.dart';

class ExportService {
  final DatabaseService _db = DatabaseService();

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 2);

  // ─── CSV ──────────────────────────────────────────────────────────────────

  Future<String> exportVehicleToCSV(Vehicle vehicle) async {
    final l10n = await currentL10n();
    final records = await _db.getRecordsForVehicle(vehicle.id!);
    final types = await _db.getMaintenanceTypesById();

    final rows = <List<String>>[
      [
        l10n.date,
        l10n.maintenanceType,
        l10n.unitKm,
        l10n.cost,
        l10n.mechanic,
        l10n.productsUsed,
        l10n.notes,
      ],
      for (final r in records)
        [
          _dateFormat.format(r.date),
          _typeName(l10n, types, r.maintenanceTypeId),
          r.kmAtService.toString(),
          r.cost != null ? r.cost!.toStringAsFixed(2) : '',
          r.mechanic ?? '',
          r.productsUsed ?? '',
          r.notes ?? '',
        ],
    ];

    final file = await _outputFile(l10n, vehicle, 'csv');
    await file.writeAsString(const ListToCsvConverter().convert(rows));
    return file.path;
  }

  // ─── PDF ──────────────────────────────────────────────────────────────────

  Future<String> exportVehicleToPDF(Vehicle vehicle) async {
    final l10n = await currentL10n();
    final records = await _db.getRecordsForVehicle(vehicle.id!);
    final totalCost = await _db.getTotalCostForVehicle(vehicle.id!);
    final types = await _db.getMaintenanceTypesById();
    final vehicleTypeName = (await _db.getVehicleTypes())
            .where((t) => t.id == vehicle.vehicleTypeId)
            .map((t) => t.name)
            .firstOrNull ??
        '-';

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Container(
            color: const PdfColor.fromInt(0xFF1565C0),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Text(
              l10n.pdfTitle,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _pdfInfoRow(l10n.pdfVehicle, vehicle.name),
                _pdfInfoRow(l10n.vehicleType, vehicleTypeName),
                _pdfInfoRow(l10n.brand, vehicle.brand),
                _pdfInfoRow(l10n.model, vehicle.model),
                _pdfInfoRow(l10n.year, vehicle.year.toString()),
                if (vehicle.licensePlate.isNotEmpty)
                  _pdfInfoRow(l10n.licensePlate, vehicle.licensePlate),
                _pdfInfoRow(l10n.currentKm, '${vehicle.currentKm} km'),
                _pdfInfoRow(
                    l10n.totalCostLabel, _currencyFormat.format(totalCost)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            l10n.recordsTitle('${records.length}'),
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (records.isEmpty)
            pw.Text(l10n.noRecords)
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF1565C0),
                  ),
                  children: [
                    _pdfTableHeader(l10n.date),
                    _pdfTableHeader(l10n.maintenanceType),
                    _pdfTableHeader(l10n.unitKm),
                    _pdfTableHeader(l10n.cost),
                  ],
                ),
                for (int i = 0; i < records.length; i++)
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: i.isEven ? PdfColors.grey50 : PdfColors.white,
                    ),
                    children: [
                      _pdfTableCell(_dateFormat.format(records[i].date)),
                      _pdfTableCell(
                          _typeName(l10n, types, records[i].maintenanceTypeId)),
                      _pdfTableCell('${records[i].kmAtService} km'),
                      _pdfTableCell(records[i].cost != null
                          ? _currencyFormat.format(records[i].cost!)
                          : '-'),
                    ],
                  ),
              ],
            ),
          pw.SizedBox(height: 24),
          pw.Text(
            l10n.generatedOn(_dateFormat.format(DateTime.now())),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ),
    );

    final file = await _outputFile(l10n, vehicle, 'pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  // ─── Share ────────────────────────────────────────────────────────────────

  Future<void> shareFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)]);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<File> _outputFile(
      AppLocalizations l10n, Vehicle vehicle, String extension) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeName = vehicle.name.replaceAll(RegExp(r'[^\w]'), '_');
    final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
    return File(
        '${dir.path}/${safeName}_${l10n.fileSuffixMaintenance}_$stamp.$extension');
  }

  String _typeName(AppLocalizations l10n, Map<String, MaintenanceType> types,
          String typeId) =>
      types[typeId]?.name ?? l10n.unknownMaintenance;

  pw.Widget _pdfInfoRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 160,
              child: pw.Text(
                label,
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
            ),
            pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      );

  pw.Widget _pdfTableHeader(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
          ),
        ),
      );

  pw.Widget _pdfTableCell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
      );
}
