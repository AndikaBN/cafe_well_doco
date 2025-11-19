import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cafe_well_doco/services/firestore_service.dart';
import 'package:cafe_well_doco/models/invite_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Halaman untuk mengelola kode undangan (Admin)
class InvitesPage extends StatefulWidget {
  const InvitesPage({super.key});

  @override
  State<InvitesPage> createState() => _InvitesPageState();
}

class _InvitesPageState extends State<InvitesPage> {
  final _firestoreService = FirestoreService();

  Future<void> _createInvite() async {
    String role = 'karyawan';
    DateTime? validUntil;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Buat Kode Undangan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'karyawan', child: Text('Karyawan')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => role = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Masa Berlaku (Opsional)'),
                subtitle: Text(
                  validUntil != null
                      ? 'Sampai: ${_formatDate(validUntil!)}'
                      : 'Tidak ada batas waktu',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => validUntil = date);
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'role': role,
                'validUntil': validUntil,
              }),
              child: const Text('Buat'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final adminId = FirebaseAuth.instance.currentUser!.uid;

      final response = await _firestoreService.createInvite(
        adminId: adminId,
        role: result['role'],
        validUntil: result['validUntil'],
      );

      if (mounted) {
        if (response['success']) {
          final code = response['code'];

          // Show code to admin
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Kode Undangan Berhasil Dibuat'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Kode undangan:',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          code,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kode disalin')),
                            );
                          },
                          tooltip: 'Salin kode',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bagikan kode ini ke calon karyawan untuk registrasi',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteInvite(InviteModel invite) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Hapus kode undangan "${invite.code}"?'),
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
      final response = await _firestoreService.deleteInvite(invite.code);

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
        title: const Text('Kode Undangan'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<InviteModel>>(
        stream: _firestoreService.getInvitesStream(),
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
                    Icons.card_giftcard_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada kode undangan',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _createInvite,
                    icon: const Icon(Icons.add),
                    label: const Text('Buat Kode Undangan'),
                  ),
                ],
              ),
            );
          }

          final invites = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invites.length,
            itemBuilder: (context, index) {
              final invite = invites[index];
              final isExpired =
                  invite.validUntil != null &&
                  DateTime.now().isAfter(invite.validUntil!);
              final isValid = invite.isValid;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isValid
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    child: Icon(
                      isValid ? Icons.confirmation_number : Icons.block,
                      color: isValid ? Colors.green : Colors.grey,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        invite.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: invite.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kode disalin')),
                          );
                        },
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Role: ${invite.role}'),
                      Text('Dibuat: ${_formatDate(invite.createdAt)}'),
                      if (invite.validUntil != null)
                        Text(
                          'Berlaku sampai: ${_formatDate(invite.validUntil!)}',
                          style: TextStyle(
                            color: isExpired
                                ? Colors.red
                                : Colors.grey.shade600,
                          ),
                        ),
                      if (invite.used)
                        const Text(
                          'Status: Sudah digunakan',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else if (isExpired)
                        const Text(
                          'Status: Kadaluarsa',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        const Text(
                          'Status: Aktif',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteInvite(invite),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createInvite,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
