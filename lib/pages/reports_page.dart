import 'package:flutter/material.dart';
import 'package:cafe_well_doco/services/firestore_service.dart';
import 'package:cafe_well_doco/models/stock_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cafe_well_doco/theme/app_colors.dart';

/// Halaman laporan stock out (pengambilan barang karyawan)
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _firestoreService = FirestoreService();
  DateTime? _startDate;
  DateTime? _endDate;
  List<StockOutModel>? _filteredData;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Default: 7 hari terakhir
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 7));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    // Ambil semua stock out dalam range tanggal
    final stream = _firestoreService.getStockOutStream();
    final allData = await stream.first;

    // Normalisasi tanggal untuk filter yang tepat
    final startOfDay = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
    );
    final endOfDay = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      23,
      59,
      59,
    );

    // Filter berdasarkan tanggal - gunakan isAfter/isBefore atau sama dengan
    final filtered = allData.where((item) {
      return !item.timestamp.isBefore(startOfDay) &&
          !item.timestamp.isAfter(endOfDay);
    }).toList();

    // Sort by timestamp descending
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    setState(() {
      _filteredData = filtered;
      _loading = false;
    });
  }

  Future<void> _backfillStockOut() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _firestoreService.backfillStockOut();

    if (mounted) {
      Navigator.pop(context); // Close loading

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            result['success'] ? 'Berhasil' : 'Gagal',
            style: TextStyle(
              color: result['success'] ? Colors.green : Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result['message']),
              if (result['created'] > 0) ...[
                const SizedBox(height: 12),
                Text(
                  'Data yang dibuat: ${result['created']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _loadData(); // Reload data
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate!, end: _endDate!),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  Future<void> _generatePDF() async {
    if (_filteredData == null || _filteredData!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data untuk diekspor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdf = pw.Document();

      // Ambil data lengkap untuk setiap stock out
      final List<Map<String, dynamic>> reportData = [];

      for (var stockOut in _filteredData!) {
        final user = await _firestoreService.getUserById(stockOut.userId);
        final product = await _firestoreService.getProduct(stockOut.productId);

        if (user != null && product != null) {
          // Hitung sisa stok setelah pengambilan
          final remainingStock = product.stock; // Current stock

          // Format tanggal bahan masuk dari product.updatedAt
          final bahanMasuk = DateFormat(
            'dd/MM/yyyy HH:mm',
          ).format(product.updatedAt);

          reportData.add({
            'karyawan': user.displayName,
            'tanggal': DateFormat(
              'dd/MM/yyyy HH:mm',
            ).format(stockOut.timestamp),
            'bahanMasuk': bahanMasuk,
            'jumlahMasuk':
                '${product.stock + stockOut.qty} ${product.unit}', // Stok sebelum diambil
            'bahanKeluar': product.name,
            'jumlahKeluar': '${stockOut.qty} ${product.unit}',
            'stok': '$remainingStock ${product.unit}',
            'catatan': stockOut.note,
          });
        }
      }

      // Build PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'LAPORAN PENGAMBILAN BARANG',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Coffee Well Doco - Inventory Management',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Periode: ${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.8),
                3: const pw.FlexColumnWidth(1.3),
                4: const pw.FlexColumnWidth(1.8),
                5: const pw.FlexColumnWidth(1.3),
                6: const pw.FlexColumnWidth(1.3),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableCell('Karyawan', isHeader: true),
                    _buildTableCell('Tanggal', isHeader: true),
                    _buildTableCell('Bahan Masuk', isHeader: true),
                    _buildTableCell('Jumlah Masuk', isHeader: true),
                    _buildTableCell('Bahan Keluar', isHeader: true),
                    _buildTableCell('Jumlah Keluar', isHeader: true),
                    _buildTableCell('Stok', isHeader: true),
                  ],
                ),
                // Data rows
                ...reportData.map(
                  (data) => pw.TableRow(
                    children: [
                      _buildTableCell(data['karyawan']),
                      _buildTableCell(data['tanggal']),
                      _buildTableCell(data['bahanMasuk']),
                      _buildTableCell(data['jumlahMasuk']),
                      _buildTableCell(data['bahanKeluar']),
                      _buildTableCell(data['jumlahKeluar']),
                      _buildTableCell(data['stok']),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'RINGKASAN',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Total Transaksi: ${reportData.length}'),
                ],
              ),
            ),

            pw.SizedBox(height: 40),

            // Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Mengetahui,'),
                    pw.SizedBox(height: 40),
                    pw.Container(
                      width: 150,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(color: PdfColors.black),
                        ),
                      ),
                      child: pw.Text('Admin', textAlign: pw.TextAlign.center),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Print or save
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name:
            'Laporan_Pengambilan_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Pengambilan Barang'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _backfillStockOut,
            tooltip: 'Sinkronisasi Data',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePDF,
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Periode',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('Ubah'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Data List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredData == null || _filteredData!.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada data pada periode ini',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredData!.length,
                    itemBuilder: (context, index) {
                      final stockOut = _filteredData![index];
                      return FutureBuilder<Map<String, dynamic>>(
                        future: _getStockOutDetails(stockOut),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            );
                          }

                          final data = snapshot.data!;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.coffeeCream,
                                child: Icon(
                                  Icons.person,
                                  color: AppColors.darkBrown,
                                ),
                              ),
                              title: Text(
                                data['karyawan'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(stockOut.timestamp),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      _buildDetailRow(
                                        'Bahan',
                                        data['bahan'] ?? '-',
                                      ),
                                      const Divider(),
                                      _buildDetailRow(
                                        'Jumlah Diambil',
                                        data['jumlah'] ?? '-',
                                      ),
                                      const Divider(),
                                      _buildDetailRow(
                                        'Sisa Stok',
                                        data['sisa'] ?? '-',
                                        valueColor: AppColors.success,
                                      ),
                                      if (stockOut.note.isNotEmpty) ...[
                                        const Divider(),
                                        _buildDetailRow(
                                          'Catatan',
                                          stockOut.note,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getStockOutDetails(
    StockOutModel stockOut,
  ) async {
    final user = await _firestoreService.getUserById(stockOut.userId);
    final product = await _firestoreService.getProduct(stockOut.productId);

    return {
      'karyawan': user?.displayName ?? 'Unknown',
      'bahan': product?.name ?? 'Unknown',
      'jumlah': '${stockOut.qty} ${product?.unit ?? ''}',
      'sisa': '${product?.stock ?? 0} ${product?.unit ?? ''}',
    };
  }
}
