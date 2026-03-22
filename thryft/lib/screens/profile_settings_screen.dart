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
                          title: const Text('Username', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(username),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Email Card
                      Card(
                        child: ListTile(
                          title: const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(email),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Password Card
                      Card(
                        child: ListTile(
                          title: const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('********'),
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
