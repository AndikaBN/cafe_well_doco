import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cafe_well_doco/services/firestore_service.dart';
import 'package:cafe_well_doco/models/request_model.dart';
import 'package:cafe_well_doco/models/product_model.dart';

/// Halaman untuk melihat riwayat request karyawan
class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Riwayat Request')),
        body: const Center(child: Text('User tidak ditemukan')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Request Saya'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<RequestModel>>(
        stream: _firestoreService.getRequestsStream(userId: userId),
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
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat request',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildRequestCard(request);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (request.status) {
      case 'queued':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Menunggu';
        break;
      case 'processing':
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        statusText = 'Diproses';
        break;
      case 'done':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Selesai';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Ditolak';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Unknown';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: FutureBuilder<ProductModel?>(
          future: _firestoreService.getProduct(request.productId),
          builder: (context, snapshot) {
            final productName = snapshot.data?.name ?? 'Loading...';
            final unit = snapshot.data?.unit ?? '';
            return Text('$productName - ${request.qty} $unit');
          },
        ),
        subtitle: Text(
          statusText,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (request.note.isNotEmpty) ...[
                  const Text(
                    'Catatan:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(request.note),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 4),
                    Text('Dibuat: ${_formatDate(request.createdAt)}'),
                  ],
                ),
                if (request.processedAt != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.done, size: 16),
                      const SizedBox(width: 4),
                      Text('Diproses: ${_formatDate(request.processedAt!)}'),
                    ],
                  ),
                ],
                if (request.rejectReason != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alasan Ditolak:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                request.rejectReason!,
                                style: TextStyle(color: Colors.red.shade900),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
