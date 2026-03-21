import 'package:flutter/material.dart';
import 'package:thryft/utils/responsive.dart';
import '../widgets/footer.dart';
import '../widgets/header.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you! Your message has been sent.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      _nameController.clear();
      _emailController.clear();
      _subjectController.clear();
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final hPadding = isMobile ? 16.0 : 80.0;
    final titleSize = isMobile ? 28.0 : 48.0;
    final subtitleSize = isMobile ? 15.0 : 18.0;
    final cardPadding = isMobile ? 20.0 : 40.0;

    return Scaffold(
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Header(),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 32 : 60,
                horizontal: hPadding,
              ),
              child: Column(
                children: [
                  // Page Title
                  Text(
                    'Contact Us',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'We\'d love to hear from you! Send us a message and we\'ll get back to you as soon as possible.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: subtitleSize,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: isMobile ? 32 : 60),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contact Form
                      Expanded(
                        child: Card(
                          elevation: 3,
                          child: Padding(
                            padding: EdgeInsets.all(cardPadding),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Send Us a Message',
                                    style: TextStyle(
                                      fontSize: isMobile ? 20 : 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 20 : 30),

                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Your Name',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.person),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  TextFormField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'Email Address',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.email),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  TextFormField(
                                    controller: _subjectController,
                                    decoration: const InputDecoration(
                                      labelText: 'Subject',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.subject),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a subject';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  TextFormField(
                                    controller: _messageController,
                                    decoration: const InputDecoration(
                                      labelText: 'Message',
                                      border: OutlineInputBorder(),
                                      alignLabelWithHint: true,
                                    ),
                                    maxLines: 6,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your message';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: isMobile ? 20 : 30),

                                  ElevatedButton(
                                    onPressed: _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF47A4F5),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: isMobile ? 16 : 20,
                                      ),
                                      textStyle: TextStyle(
                                        fontSize: isMobile ? 16 : 18,
                                      ),
                                    ),
                                    child: const Text('Send Message'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }
}
