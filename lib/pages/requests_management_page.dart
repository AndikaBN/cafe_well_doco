import 'package:flutter/material.dart';
import 'package:cafe_well_doco/services/firestore_service.dart';
import 'package:cafe_well_doco/models/request_model.dart';
import 'package:cafe_well_doco/models/product_model.dart';
import 'package:cafe_well_doco/models/user_model.dart';

/// Halaman untuk mengelola requests (Admin)
/// Admin bisa melihat dan memproses request dari karyawan
class RequestsManagementPage extends StatefulWidget {
  const RequestsManagementPage({super.key});

  @override
  State<RequestsManagementPage> createState() => _RequestsManagementPageState();
}

class _RequestsManagementPageState extends State<RequestsManagementPage> {
  final _firestoreService = FirestoreService();
  String _selectedStatus = 'queued'; // queued, processing, done, rejected, all

  Future<void> _processRequest(RequestModel request, bool approve) async {
    String? rejectReason;

    if (!approve) {
      final controller = TextEditingController();
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Alasan Penolakan'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Masukkan alasan penolakan',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Tolak'),
            ),
          ],
        ),
      );

      if (result != true) return;
      rejectReason = controller.text.trim();
      if (rejectReason.isEmpty) rejectReason = 'Ditolak oleh admin';
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Proses request ini? Stok akan dikurangi.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Proses'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    final result = await _firestoreService.processRequest(
      requestId: request.id,
      approve: approve,
      rejectReason: rejectReason,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Request'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Semua')),
                      DropdownMenuItem(
                        value: 'queued',
                        child: Text('Menunggu'),
                      ),
                      DropdownMenuItem(
                        value: 'processing',
                        child: Text('Diproses'),
                      ),
                      DropdownMenuItem(value: 'done', child: Text('Selesai')),
                      DropdownMenuItem(
                        value: 'rejected',
                        child: Text('Ditolak'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedStatus = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: StreamBuilder<List<RequestModel>>(
              stream: _firestoreService.getRequestsStream(
                status: _selectedStatus == 'all' ? null : _selectedStatus,
              ),
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
                          'Tidak ada request',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    Color statusColor;
    IconData statusIcon;

    switch (request.status) {
      case 'queued':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'processing':
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case 'done':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<UserModel?>(
              future: _firestoreService.getUsersStream().first.then(
                (users) => users.firstWhere((u) => u.uid == request.userId),
              ),
              builder: (context, snapshot) {
                final userName = snapshot.data?.displayName ?? 'Loading...';
                return Text('Oleh: $userName');
              },
            ),
            Text(
              'Status: ${_getStatusText(request.status)}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ],
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
                Text('Dibuat: ${_formatDate(request.createdAt)}'),
                if (request.processedAt != null)
                  Text('Diproses: ${_formatDate(request.processedAt!)}'),
                if (request.rejectReason != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Alasan ditolak: ${request.rejectReason}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                if (request.status == 'queued') ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _processRequest(request, false),
                        icon: const Icon(Icons.close),
                        label: const Text('Tolak'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _processRequest(request, true),
                        icon: const Icon(Icons.check),
                        label: const Text('Proses'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'queued':
        return 'Menunggu';
      case 'processing':
        return 'Diproses';
      case 'done':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
