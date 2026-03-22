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
  bool _isLoading = false;

  Map<String, dynamic>? _userAddress;

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase
          .from('address')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _userAddress = response;
        });
      }
    } catch (e) {
      // Ignore if not present
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _updateField(String field, String value) async {
    setState(() => _isLoading = true);
    try {
      if (field == 'username') {
        await _supabase.auth.updateUser(
          UserAttributes(data: {'username': value}),
        );
      } else if (field == 'email') {
        await _supabase.auth.updateUser(UserAttributes(email: value));
        _showSnackBar('Email updated! Please check your inbox to verify.');
      } else if (field == 'password') {
        await _supabase.auth.updateUser(UserAttributes(password: value));
      }

      if (field != 'email') {
        _showSnackBar('Successfully updated ${field.toLowerCase()}');
      }
    } on AuthException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      _showSnackBar('An error occurred during update', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAddressField(String field, String value) async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Make sure we supply defaults for required fields in case they don't exist yet
      final data = {
        'user_id': user.id,
        'street': _userAddress?['street'] ?? '',
        'city': _userAddress?['city'] ?? '',
        'postal_code': _userAddress?['postal_code'] ?? '',
        'country': _userAddress?['country'] ?? '',
      };

      if (_userAddress != null) {
        data.addAll(_userAddress!);
      }
      data[field] = value;

      await _supabase.from('address').upsert(data);
      _showSnackBar('Successfully updated address');
      await _fetchAddress();
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newValue = controller.text.trim();
                  Navigator.pop(context);

                  if (field == 'street' ||
                      field == 'city' ||
                      field == 'postal_code' ||
                      field == 'country') {
                    await _updateAddressField(field, newValue);
                  } else {
                    await _updateField(field, newValue);
                  }
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
      body: Stack(
        children: [
          SingleChildScrollView(
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
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
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
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
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
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _showEditDialog(
                                  'Password',
                                  'password',
                                  null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Address Settings',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Street Card
                          Card(
                            child: ListTile(
                              title: const Text(
                                'Street',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                _userAddress?['street'] ?? 'Not set',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _showEditDialog(
                                  'Street',
                                  'street',
                                  _userAddress?['street'],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // City Card
                          Card(
                            child: ListTile(
                              title: const Text(
                                'City',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                _userAddress?['city'] ?? 'Not set',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _showEditDialog(
                                  'City',
                                  'city',
                                  _userAddress?['city'],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Postal Code Card
                          Card(
                            child: ListTile(
                              title: const Text(
                                'Postal Code',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                _userAddress?['postal_code'] ?? 'Not set',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _showEditDialog(
                                  'Postal Code',
                                  'postal_code',
                                  _userAddress?['postal_code'],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Country Card
                          Card(
                            child: ListTile(
                              title: const Text(
                                'Country',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                _userAddress?['country'] ?? 'Not set',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _showEditDialog(
                                  'Country',
                                  'country',
                                  _userAddress?['country'],
                                ),
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
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
