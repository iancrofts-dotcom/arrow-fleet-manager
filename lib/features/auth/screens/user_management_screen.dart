import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'add_user_screen.dart';
import 'edit_user_screen.dart';
import '../widgets/delete_user_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState
    extends State<UserManagementScreen> {
  final UserService _userService = UserService.instance;
  final AuthService _authService = AuthService.instance;

  bool get _isAdmin =>
      _authService.currentUser?.role == UserRole.admin;

  final TextEditingController _searchController =
      TextEditingController();

  List<User> _users = [];
  List<User> _filteredUsers = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final users = await _userService.getUsers();

    if (!mounted) return;

    setState(() {
      _users = users;
      _filteredUsers = users;
      _loading = false;
    });
  }

  void _filterUsers() {
    final query =
        _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredUsers = _users.where((user) {
        return user.username
                .toLowerCase()
                .contains(query) ||
            user.role.name
                .toLowerCase()
                .contains(query);
      }).toList();
    });
  }

  Future<void> _refresh() async {
    await _loadUsers();
  }

  Future<void> _editUser(User user) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditUserScreen(user: user),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _loadUsers();
    }
  }

  Future<void> _deleteUser(User user) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteUserDialog(
        username: user.username,
      ),
    );

    if (!mounted) return;

    if (confirm != true) return;

    if (user.username == 'admin') {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'The default Administrator cannot be deleted.',
          ),
        ),
      );
      return;
    }

    await _userService.deleteUser(user.id);

    if (!mounted) return;

    await _loadUsers();

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${user.username} deleted.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 20),
              Text(
                'You do not have permission\n'
                'to access this page.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final created =
              await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) =>
                  const AddUserScreen(),
            ),
          );

          if (!mounted) return;

          if (created == true) {
            await _loadUsers();
          }
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: _filteredUsers.isEmpty
                        ? const Center(
                            child: Text(
                              'No users found.',
                            ),
                          )
                        : ListView.builder(
                            itemCount:
                                _filteredUsers.length,
                            itemBuilder:
                                (context, index) {
                              final user =
                                  _filteredUsers[index];

                              return Card(
                                margin:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      user.username
                                          .substring(0, 1)
                                          .toUpperCase(),
                                    ),
                                  ),
                                  title:
                                      Text(user.username),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        user.role
                                            .displayName,
                                      ),
                                      Text(
                                        user.isActive
                                            ? 'Active'
                                            : 'Inactive',
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                        ),
                                        onPressed: () =>
                                            _editUser(user),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _deleteUser(user),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}