import 'package:flutter/material.dart';
import 'package:cafe_well_doco/services/firestore_service.dart';
import 'package:cafe_well_doco/models/user_model.dart';

/// Halaman untuk approval user baru (Admin)
class UserApprovalPage extends StatefulWidget {
  const UserApprovalPage({super.key});

  @override
  State<UserApprovalPage> createState() => _UserApprovalPageState();
}

class _UserApprovalPageState extends State<UserApprovalPage> {
  final _firestoreService = FirestoreService();

  Future<void> _updateApproval(UserModel user, bool approved) async {
    final result = await _firestoreService.updateUserApproval(
      userId: user.uid,
      approved: approved,
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Approval User'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Menunggu Approval'),
              Tab(text: 'Sudah Approved'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserList(approved: false),
            _buildUserList(approved: true),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList({required bool approved}) {
    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.getUsersStream(approved: approved),
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
                  approved
                      ? Icons.check_circle_outline
                      : Icons.pending_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  approved
                      ? 'Semua user sudah aktif'
                      : 'Tidak ada user menunggu',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: user.isAdmin
                      ? Colors.purple.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
                  child: Icon(
                    user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: user.isAdmin ? Colors.purple : Colors.blue,
                  ),
                ),
                title: Text(
                  user.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(user.email),
                    const SizedBox(height: 2),
                    Text(
                      'Role: ${user.role}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Terdaftar: ${_formatDate(user.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: approved
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'approve',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check,
                                  size: 20,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 8),
                                Text('Setujui'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'reject',
                            child: Row(
                              children: [
                                Icon(Icons.close, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Tolak'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'approve') {
                            _updateApproval(user, true);
                          } else if (value == 'reject') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Konfirmasi'),
                                content: Text(
                                  'Menolak user akan tetap menyimpan data mereka tetapi mereka tidak bisa login. Yakin menolak "${user.displayName}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Tolak'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              _updateApproval(user, false);
                            }
                          }
                        },
                      ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
