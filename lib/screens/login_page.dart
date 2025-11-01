import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/filemaker_service.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Prefill test user credentials for development/testing only
    if (kDebugMode) {
      _usernameController.text = 'nafisa@test.com';
      _passwordController.text = 'Welcome123\$';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _usernameController.text.trim();
      final password = _passwordController.text.trim();
      
      final fileMakerService = Provider.of<FileMakerService>(context, listen: false);
      
      // Step 1: Authenticate with FileMaker to get access
      await fileMakerService.authenticate();
      
      // Small delay to ensure token is fully set
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Step 2: Validate user credentials against staff table
      final staff = await fileMakerService.getStaffByEmail(email);
      
      if (staff == null) {
        throw Exception('User not found');
      }
      
      // Compare password with Password_raw field
      if (staff.passwordRaw != password) {
        throw Exception('Invalid password');
      }
      
      // Check if staff is active
      if (staff.active == false) {
        throw Exception('Account is inactive');
      }
      
      // Step 3: Exchange FileMaker token for Sanctum token (no re-authentication needed)
      print('🔍 LOGIN DEBUG: Starting Step 3 - Token Exchange');
      try {
        // Get the FileMaker token that was just obtained
        final fileMakerToken = fileMakerService.token;
        print('🔍 LOGIN DEBUG: FileMaker token retrieved');
        print('🔍 LOGIN DEBUG: Token is null: ${fileMakerToken == null}');
        print('🔍 LOGIN DEBUG: Token isEmpty: ${fileMakerToken?.isEmpty ?? true}');
        if (fileMakerToken != null) {
          print('🔍 LOGIN DEBUG: Token length: ${fileMakerToken.length}');
          print('🔍 LOGIN DEBUG: Token preview: ${fileMakerToken.substring(0, fileMakerToken.length > 20 ? 20 : fileMakerToken.length)}...');
        }
        
        if (fileMakerToken != null && fileMakerToken.isNotEmpty) {
          print('🔐 Exchanging FileMaker token for Sanctum token...');
          print('🔍 LOGIN DEBUG: Calling AuthService.exchangeFileMakerToken');
          final sanctumToken = await AuthService.exchangeFileMakerToken(
            filemakerToken: fileMakerToken,
            email: email,
            database: 'EIDBI',
          );
          
          print('🔍 LOGIN DEBUG: Exchange completed, sanctumToken is null: ${sanctumToken == null}');
          
          if (sanctumToken != null) {
            print('✅ Sanctum token obtained via FileMaker token exchange');
            print('🔍 LOGIN DEBUG: Sanctum token length: ${sanctumToken.length}');
          } else {
            print('⚠️ Sanctum token not received, but continuing with FileMaker auth');
            // Continue anyway - MCP features will fall back to direct API
          }
        } else {
          print('⚠️ No FileMaker token available for exchange');
          print('🔍 LOGIN DEBUG: Token was null or empty, cannot exchange');
        }
      } catch (e, stackTrace) {
        print('⚠️ Failed to exchange FileMaker token for Sanctum token: $e');
        print('🔍 LOGIN DEBUG: Exception stack trace: $stackTrace');
        print('⚠️ Continuing with FileMaker auth only - MCP features will use fallback');
        // Don't block login if Sanctum auth fails - user can still use the app
      }
      print('🔍 LOGIN DEBUG: Step 3 completed');
      
      // Step 4: Navigate to start visit page
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/start-visit');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo/Title
                      Icon(
                        Icons.medical_services,
                        size: 64,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'DataSheets',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ABA Data Collection System',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email Field
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 24),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/mcp-test'),
                        icon: const Icon(Icons.science, size: 18),
                        label: const Text('MCP API Test'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
