import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class AdminXPostScreen extends StatefulWidget {
  const AdminXPostScreen({super.key});

  @override
  State<AdminXPostScreen> createState() => _AdminXPostScreenState();
}

class _AdminXPostScreenState extends State<AdminXPostScreen> {
  final _tweetController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _tweetController.dispose();
    super.dispose();
  }

  Future<void> _postTweet() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<AdminProvider>(context, listen: false);

    try {
      await provider.postTweet(_tweetController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tweet posted successfully!'),
              backgroundColor: Colors.green),
        );
        _tweetController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error posting tweet: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AdminProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Post to X (Twitter)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Compose Tweet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will be posted to the official @Catcoin account.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tweetController,
                maxLines: 5,
                maxLength: 280,
                decoration: const InputDecoration(
                  hintText: "What's happening?",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: isLoading ? null : _postTweet,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                label: const Text('Post Tweet'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.black, // X branding color
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


