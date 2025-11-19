import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cafe_well_doco/services/firestore_service.dart';
import 'package:cafe_well_doco/models/product_model.dart';

/// Halaman untuk membuat request barang (Karyawan)
class CreateRequestPage extends StatefulWidget {
  const CreateRequestPage({super.key});

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  final _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _noteController = TextEditingController();

  ProductModel? _selectedProduct;
  bool _loading = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() || _selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih produk dan isi jumlah'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Cek stok tersedia
    final qty = int.parse(_qtyController.text);
    if (qty > _selectedProduct!.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Jumlah melebihi stok tersedia (${_selectedProduct!.stock} ${_selectedProduct!.unit})',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Gunakan createRequestDirect untuk langsung proses (OPSI A)
    // Atau gunakan createRequestQueued untuk masuk antrian (OPSI B)

    // OPSI A: Direct processing (langsung kurangi stok)
    final result = await _firestoreService.createRequestDirect(
      userId: userId,
      productId: _selectedProduct!.id,
      qty: qty,
      note: _noteController.text.trim(),
    );

    // OPSI B: Queued processing (admin yang proses manual)
    // Uncomment baris di bawah dan comment yang atas untuk gunakan OPSI B
    // final result = await _firestoreService.createRequestQueued(
    //   userId: userId,
    //   productId: _selectedProduct!.id,
    //   qty: qty,
    //   note: _noteController.text.trim(),
    // );

    if (mounted) {
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success']) {
        // Kembali ke halaman sebelumnya
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Barang'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Request',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Pilih Produk',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<ProductModel>>(
                        stream: _firestoreService.getProductsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text('Belum ada produk tersedia');
                          }

                          final products = snapshot.data!;

                          return DropdownButtonFormField<ProductModel>(
                            value: _selectedProduct,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Pilih produk',
                            ),
                            items: products.map((product) {
                              return DropdownMenuItem(
                                value: product,
                                child: Text(
                                  '${product.name} (Tersedia: ${product.stock} ${product.unit})',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedProduct = value);
                            },
                            validator: (value) {
                              if (value == null) return 'Pilih produk';
                              return null;
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 16),
                      Text(
                        'Jumlah yang Diminta',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: 'Masukkan jumlah',
                          suffixText: _selectedProduct?.unit ?? '',
                          helperText: _selectedProduct != null
                              ? 'Stok tersedia: ${_selectedProduct!.stock} ${_selectedProduct!.unit}'
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Masukkan jumlah';
                          }
                          final qty = int.tryParse(value);
                          if (qty == null || qty <= 0) {
                            return 'Jumlah harus lebih dari 0';
                          }
                          if (_selectedProduct != null &&
                              qty > _selectedProduct!.stock) {
                            return 'Melebihi stok tersedia';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),
                      Text(
                        'Catatan (Opsional)',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Contoh: Untuk keperluan shift pagi',
                        ),
                      ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submitRequest,
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Kirim Request',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Info card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Request akan diproses secara otomatis jika stok mencukupi. '
                          'Anda akan mendapat notifikasi setelah request diproses.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
