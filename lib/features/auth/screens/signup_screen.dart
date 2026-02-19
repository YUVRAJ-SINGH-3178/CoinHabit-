import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/core/constants/app_colors.dart';
import 'package:version/navigation/route_names.dart';
import 'package:version/services/supabase_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _acceptedPolicies = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate() || !_acceptedPolicies) {
      if (!_acceptedPolicies && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please accept Terms and Privacy Policy.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final isUsernameTaken =
          await _isUsernameTaken(_usernameController.text.trim());
      if (isUsernameTaken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username is already taken.')),
          );
        }
        return;
      }

      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'display_name': _fullNameController.text.trim(),
          'username': _usernameController.text.trim(),
        },
      );

      if (!mounted) {
        return;
      }

      if (response.user != null) {
        context.go(RouteNames.profileSetup);
      }
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapSignupError(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create your account',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set up your profile and start building better saving habits.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textMid),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter your full name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                final username = value?.trim() ?? '';
                                final regex = RegExp(r'^[a-z0-9_]{3,20}$');
                                if (!regex.hasMatch(username)) {
                                  return '3-20 chars: lowercase letters, numbers, underscores';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline_rounded),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter a password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: const InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: Icon(Icons.verified_user_outlined),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            CheckboxListTile(
                              value: _acceptedPolicies,
                              onChanged: _isLoading
                                  ? null
                                  : (value) => setState(
                                        () =>
                                            _acceptedPolicies = value ?? false,
                                      ),
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'I agree to the Terms and Privacy Policy',
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _openUrl(
                                            'https://example.com/privacy',
                                          ),
                                  child: const Text('Privacy Policy'),
                                ),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _openUrl(
                                            'https://example.com/terms',
                                          ),
                                  child: const Text('Terms'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: _isLoading ? null : _signUp,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Text('Create Account'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => context.go(RouteNames.login),
                      child: const Text('Already have an account? Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _isUsernameTaken(String username) async {
    try {
      final usersResult = await supabase
          .from('users')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      if (usersResult != null) {
        return true;
      }
    } catch (_) {}

    try {
      final profilesResult = await supabase
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      return profilesResult != null;
    } catch (_) {
      return false;
    }
  }

  String _mapSignupError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('already registered')) {
      return 'This email is already registered.';
    }
    if (message.contains('password')) {
      return 'Please choose a stronger password.';
    }
    return 'Unable to create account right now. Please try again.';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
