import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
                      const SizedBox(height: 20),
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
                            // TODO: Implement favourites view
                          },
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
}
