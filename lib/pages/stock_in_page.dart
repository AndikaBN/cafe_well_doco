import 'package:flutter/material.dart';
import 'package:cafe_well_doco/services/firestore_service.dart';
import 'package:cafe_well_doco/models/product_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Halaman untuk menambah stok produk (Admin)
class StockInPage extends StatefulWidget {
  const StockInPage({super.key});

  @override
  State<StockInPage> createState() => _StockInPageState();
}

class _StockInPageState extends State<StockInPage> {
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

  Future<void> _submitStockIn() async {
    if (!_formKey.currentState!.validate() || _selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih produk dan isi jumlah'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final qty = int.parse(_qtyController.text);
    final adminId = FirebaseAuth.instance.currentUser!.uid;

    final result = await _firestoreService.addStock(
      productId: _selectedProduct!.id,
      qty: qty,
      adminId: adminId,
      note: _noteController.text.trim(),
    );

    if (mounted) {
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success']) {
        // Reset form
        _qtyController.clear();
        _noteController.clear();
        setState(() => _selectedProduct = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Stok'),
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
                            return const Text('Belum ada produk');
                          }

                          final products = snapshot.data!;

                          // Reset selected product jika tidak ada dalam list
                          if (_selectedProduct != null &&
                              !products.any(
                                (p) => p.id == _selectedProduct!.id,
                              )) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() => _selectedProduct = null);
                            });
                          }

                          return DropdownButtonFormField<String>(
                            value: _selectedProduct?.id,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Pilih produk',
                            ),
                            items: products.map((product) {
                              return DropdownMenuItem(
                                value: product.id,
                                child: Text(
                                  '${product.name} (Stok: ${product.stock} ${product.unit})',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedProduct = products.firstWhere(
                                  (p) => p.id == value,
                                );
                              });
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
                        'Jumlah Stok Masuk',
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
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Masukkan jumlah';
                          }
                          final qty = int.tryParse(value);
                          if (qty == null || qty <= 0) {
                            return 'Jumlah harus lebih dari 0';
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
                          hintText: 'Contoh: Pembelian dari supplier A',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submitStockIn,
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Tambah Stok',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Riwayat Stok Masuk',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              StreamBuilder(
                stream: _firestoreService.getStockInStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('Belum ada riwayat')),
                      ),
                    );
                  }

                  final stockInList = snapshot.data!;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stockInList.length,
                    itemBuilder: (context, index) {
                      final stockIn = stockInList[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.add, color: Colors.white),
                          ),
                          title: FutureBuilder<ProductModel?>(
                            future: _firestoreService.getProduct(
                              stockIn.productId,
                            ),
                            builder: (context, snapshot) {
                              final productName =
                                  snapshot.data?.name ?? 'Loading...';
                              return Text(productName);
                            },
                          ),
                          subtitle: Text(
                            '${stockIn.note}\n${_formatDate(stockIn.timestamp)}',
                          ),
                          trailing: Text(
                            '+${stockIn.qty}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
