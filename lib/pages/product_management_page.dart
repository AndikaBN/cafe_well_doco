import 'package:flutter/material.dart';
import 'package:cafe_well_doco/services/firestore_service.dart';
import 'package:cafe_well_doco/models/product_model.dart';

/// Halaman untuk mengelola produk (Admin)
class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  final _firestoreService = FirestoreService();

  Future<void> _showAddProductDialog() async {
    final nameController = TextEditingController();
    final stockController = TextEditingController();
    final unitController = TextEditingController(text: 'pcs');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Produk Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Produk',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stok Awal',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(
                labelText: 'Satuan (kg, liter, pcs, dll)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final stock = int.tryParse(stockController.text) ?? 0;

      final response = await _firestoreService.addProduct(
        name: nameController.text,
        stock: stock,
        unit: unitController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditProductDialog(ProductModel product) async {
    final nameController = TextEditingController(text: product.name);
    final unitController = TextEditingController(text: product.unit);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Produk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Produk',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(
                labelText: 'Satuan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Catatan: Stok saat ini ${product.stock} ${product.unit}. Untuk mengubah stok, gunakan menu "Tambah Stok".',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result == true) {
      final response = await _firestoreService.updateProduct(
        productId: product.id,
        name: nameController.text,
        unit: unitController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus produk "${product.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await _firestoreService.deleteProduct(product.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: _firestoreService.getProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada produk',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddProductDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Produk'),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final stockLow = product.stock < 10;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: stockLow
                        ? Colors.red.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                    child: Icon(
                      Icons.inventory_2,
                      color: stockLow ? Colors.red : Colors.blue,
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Stok: ${product.stock} ${product.unit}'),
                      if (stockLow)
                        Text(
                          'Stok rendah!',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: stockLow,
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditProductDialog(product);
                      } else if (value == 'delete') {
                        _deleteProduct(product);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
