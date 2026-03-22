import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/header.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _supabase = Supabase.instance.client;

  void _showEditDialog(String title, String field, String? currentValue) {
    final controller = TextEditingController(
      text: field == 'password' ? '' : currentValue,
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              obscureText: field == 'password',
              decoration: InputDecoration(
                labelText: 'New $title',
                border: const OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a valid $title';
                }
                if (field == 'email' &&
                    (!val.contains('@') || !val.contains('.'))) {
                  return 'Please enter a valid email address';
                }
                if (field == 'password' && val.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newValue = controller.text.trim();
                  Navigator.pop(context);
                  // TODO: Step 3 will add the actual Supabase update logic here
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view settings.')),
      );
    }

    final username = user.userMetadata?['username'] ?? 'No Username Provided';
    final email = user.email ?? 'No Email Provided';

    return Scaffold(
      drawer: const AppDrawer(), // Added AppDrawer in case of mobile view
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Header(),
            const SizedBox(height: 40),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile Settings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Username Card
                      Card(
                        child: ListTile(
                          title: const Text(
                            'Username',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(username),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditDialog(
                              'Username',
                              'username',
                              username,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Email Card
                      Card(
                        child: ListTile(
                          title: const Text(
                            'Email',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(email),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showEditDialog('Email', 'email', email),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Password Card
                      Card(
                        child: ListTile(
                          title: const Text(
                            'Password',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('********'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showEditDialog('Password', 'password', null),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
            const Footer(),
          ],
        ),
      ),
    );
  }
}
