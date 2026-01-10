import 'package:flutter/material.dart';
import 'package:shop_ims/services/dao.dart';
import 'package:shop_ims/models/models.dart';

class UserPage extends StatefulWidget {
  final User user;

  const UserPage({super.key, required this.user});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final UserDao _userDao = UserDao();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _roleController = TextEditingController();

  Future<void> _addUser() async {
    await _userDao.insertUser(
      User(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _roleController.text,
      ),
    );
    setState(() {});
  }

  Future<void> _deleteUser(int id) async {
    await _userDao.deleteUser(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users (${widget.user.role})'),
      ),
      body: Column(
        children: [
          // ADD USER FORM
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                TextField(
                  controller: _roleController,
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _addUser,
                  child: const Text('Add User'),
                ),
              ],
            ),
          ),

          const Divider(),

          // USER LIST
          Expanded(
            child: FutureBuilder<List<User>>(
              future: _userDao.getUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      title: Text(user.fullName),
                      subtitle: Text('${user.email} (${user.role})'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteUser(user.id!),
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
}
