import 'package:flutter/material.dart';
import 'package:cafe_well_doco/services/firestore_service.dart';

/// Halaman utility untuk populate data sampel produk
/// Hanya untuk development/testing
class SampleDataSeederPage extends StatefulWidget {
  const SampleDataSeederPage({super.key});

  @override
  State<SampleDataSeederPage> createState() => _SampleDataSeederPageState();
}

class _SampleDataSeederPageState extends State<SampleDataSeederPage> {
  final _firestoreService = FirestoreService();
  bool _loading = false;
  String _status = '';

  final List<Map<String, dynamic>> _sampleProducts = [
    {'name': 'Kopi Arabica', 'stock': 100, 'unit': 'kg'},
    {'name': 'Kopi Robusta', 'stock': 150, 'unit': 'kg'},
    {'name': 'Susu Full Cream', 'stock': 50, 'unit': 'liter'},
    {'name': 'Gula Pasir', 'stock': 200, 'unit': 'kg'},
    {'name': 'Cup Kertas 8oz', 'stock': 500, 'unit': 'pcs'},
    {'name': 'Cup Kertas 12oz', 'stock': 500, 'unit': 'pcs'},
    {'name': 'Cup Kertas 16oz', 'stock': 300, 'unit': 'pcs'},
    {'name': 'Sedotan Plastik', 'stock': 1000, 'unit': 'pcs'},
    {'name': 'Tutup Cup', 'stock': 800, 'unit': 'pcs'},
    {'name': 'Sirup Vanila', 'stock': 20, 'unit': 'botol'},
    {'name': 'Sirup Karamel', 'stock': 20, 'unit': 'botol'},
    {'name': 'Sirup Hazelnut', 'stock': 15, 'unit': 'botol'},
    {'name': 'Whipped Cream', 'stock': 30, 'unit': 'kaleng'},
    {'name': 'Cokelat Powder', 'stock': 40, 'unit': 'kg'},
    {'name': 'Matcha Powder', 'stock': 25, 'unit': 'kg'},
  ];

  Future<void> _seedData() async {
    setState(() {
      _loading = true;
      _status = 'Memulai seeding...';
    });

    int success = 0;
    int failed = 0;

    for (int i = 0; i < _sampleProducts.length; i++) {
      final product = _sampleProducts[i];

      setState(() {
        _status =
            'Menambahkan ${product['name']} (${i + 1}/${_sampleProducts.length})...';
      });

      final result = await _firestoreService.addProduct(
        name: product['name'],
        stock: product['stock'],
        unit: product['unit'],
      );

      if (result['success']) {
        success++;
      } else {
        failed++;
      }

      // Delay untuk menghindari rate limiting
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() {
      _loading = false;
      _status = 'Selesai! Berhasil: $success, Gagal: $failed';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seeding selesai! Berhasil: $success, Gagal: $failed'),
          backgroundColor: failed == 0 ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Data Seeder'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tool ini untuk development/testing. Pastikan Anda login sebagai Admin!',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Data yang Akan Ditambahkan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _sampleProducts.length,
                itemBuilder: (context, index) {
                  final product = _sampleProducts[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.withOpacity(0.2),
                        child: Text('${index + 1}'),
                      ),
                      title: Text(product['name']),
                      subtitle: Text(
                        'Stok: ${product['stock']} ${product['unit']}',
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (_status.isNotEmpty) ...[
              Text(
                _status,
                style: TextStyle(
                  color: _loading ? Colors.blue : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _seedData,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload),
                label: Text(
                  _loading ? 'Sedang Menambahkan...' : 'Mulai Seed Data',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
