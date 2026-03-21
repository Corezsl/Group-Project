import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thryft/widgets/footer.dart';
import 'package:thryft/widgets/header.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Header(),
            const SizedBox(height: 20),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Login Status Pill
                      _buildUserStatus(),
                      const SizedBox(height: 24),
                      // Placeholder buttons for account management options
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Profile Settings'),
                          subtitle: const Text(
                            'Manage your personal information',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            context.push('/profile-settings');
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.list_alt),
                          title: const Text('My Listings'),
                          subtitle: const Text(
                            'View and manage your items for sale',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // TODO: Implement listings management
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.shopping_bag_outlined),
                          title: const Text('My Orders'),
                          subtitle: const Text('Track your purchases'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // TODO: Implement order tracking
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.favorite_outline),
                          title: const Text('My Favourites'),
                          subtitle: const Text('View your saved items'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            context.push('/wishlist');
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await Supabase.instance.client.auth.signOut();
                            if (context.mounted) {
                              context.go('/');
                            }
                          },
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text(
                            'Log out',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.red.shade200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Footer(),
          ],
        ),
      ),
    );
  }
  Widget _buildUserStatus() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Logged In',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user.email ?? '',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
