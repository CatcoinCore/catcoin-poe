import 'package:flutter/material.dart';
import 'package:cat_poe/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';
import 'email_verification_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.loginTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: l.loginEmailOrUsername,
                hintText: l.loginEmailHint,
              ),
            ),
            const SizedBox(height: 3),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: l.loginPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 20),
            if (authProvider.error != null)
              Text(authProvider.error!,
                  style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            authProvider.isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      await authProvider.login(
                        _usernameController.text,
                        _passwordController.text,
                      );

                      if (!context.mounted) return;

                      if (authProvider.error != null) {
                        final error = authProvider.error!;
                        if (error.contains('Email not verified')) {
                          final input = _usernameController.text.trim();
                          if (input.contains('@')) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EmailVerificationScreen(email: input),
                              ),
                            ).then((_) {
                              if (context.mounted) {
                                Provider.of<AuthProvider>(context,
                                        listen: false)
                                    .clearError();
                              }
                            });
                            return;
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l.loginUseEmailForVerification),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(error),
                              backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: Text(l.loginButton),
                  ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              child: Text(l.loginCreateAccount),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen()),
                );
              },
              child: Text(l.loginForgotPassword),
            ),
          ],
        ),
      ),
    );
  }
}

