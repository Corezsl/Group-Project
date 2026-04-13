import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/app_drawer.dart';
import 'package:thryft/widgets/header.dart';
import 'package:uuid/uuid.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Map<String, dynamic>? _userAddress;
  String? _currentAvatarUrl;
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAddress();
    _fetchProfile();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
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

  Future<void> _fetchProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _supabase
          .from('profiles')
          .select('avatar_url, bio')
          .eq('id', user.id)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() {
          _currentAvatarUrl = data['avatar_url']?.toString();
          _bioController.text = data['bio']?.toString() ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last;
      final fileName = 'avatars/${user.id}.${const Uuid().v4()}.$ext';

      await _supabase.storage
          .from('product-images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$ext'),
          );

      final url = _supabase.storage
          .from('product-images')
          .getPublicUrl(fileName);

      await _supabase
          .from('profiles')
          .update({'avatar_url': url})
          .eq('id', user.id);

      if (mounted) setState(() => _currentAvatarUrl = url);
      _showSnackBar('Profile picture updated');
    } catch (e) {
      _showSnackBar('Error uploading avatar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBio() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      await _supabase
          .from('profiles')
          .update({'bio': _bioController.text.trim()})
          .eq('id', user.id);
      _showSnackBar('Bio updated');
    } catch (e) {
      _showSnackBar('Error updating bio', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  Future<void> _updateFullAddress(
    String street,
    String city,
    String postalCode,
    String country,
  ) async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final Map<String, dynamic> data = {
        'user_id': user.id,
        'street': street,
        'city': city,
        'postal_code': postalCode,
        'country': country,
      };

      if (_userAddress != null) {
        data.addAll(_userAddress!);
        data['street'] = street;
        data['city'] = city;
        data['postal_code'] = postalCode;
        data['country'] = country;
      }

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

  void _showAddressDialog() {
    final streetCtrl = TextEditingController(
      text: _userAddress?['street'] ?? '',
    );
    final cityCtrl = TextEditingController(text: _userAddress?['city'] ?? '');
    final postalCtrl = TextEditingController(
      text: _userAddress?['postal_code'] ?? '',
    );
    final countryCtrl = TextEditingController(
      text: _userAddress?['country'] ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Address'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: streetCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Street',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: postalCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Postal Code',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: countryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                ],
              ),
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
                  Navigator.pop(context);
                  await _updateFullAddress(
                    streetCtrl.text.trim(),
                    cityCtrl.text.trim(),
                    postalCtrl.text.trim(),
                    countryCtrl.text.trim(),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
                  await _updateField(field, newValue);
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
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => context.go('/account'),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Profile Settings',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Avatar
                          Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 48,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: _currentAvatarUrl != null
                                      ? NetworkImage(_currentAvatarUrl!)
                                      : null,
                                  child: _currentAvatarUrl == null
                                      ? const Icon(Icons.person, size: 48, color: Colors.grey)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickAndUploadAvatar,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(255, 71, 164, 245),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
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
                          const SizedBox(height: 12),

                          // Bio Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bio',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _bioController,
                                    maxLines: 3,
                                    maxLength: 200,
                                    decoration: const InputDecoration(
                                      hintText: 'Tell buyers a little about yourself...',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.all(12),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: _updateBio,
                                      child: const Text('Save Bio'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Address Settings',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: _showAddressDialog,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Street Card
                          Card(
                            child: ListTile(
                              title: const Text(
                                'Number/Street',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                _userAddress?['street'] ?? 'Not set',
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
