import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'rahul@agrichain.ai');
  final _passwordController = TextEditingController(text: 'password123');

  void _handleLogin(String role) {
    ref.read(currentUserProvider.notifier).setRole(role);
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.5), width: 1.5),
                  ),
                  child: const Center(
                    child: Text('🌾', style: TextStyle(fontSize: 36)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'AgriChain AI',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Agricultural Supply Chain Intelligence & Traceability',
                  style: TextStyle(fontSize: 13, color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),

              // Email input
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryGreen),
                ),
              ),
              const SizedBox(height: 16),

              // Password input
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryGreen),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () => _handleLogin(AppConstants.roleFarmer),
                child: const Text('Sign In to Account'),
              ),
              const SizedBox(height: 36),

              // Quick Role Switching for Hackathon Presentation
              Row(
                children: [
                  const Expanded(child: Divider(color: AppTheme.darkBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR SELECT DEMO ROLE',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppTheme.darkBorder)),
                ],
              ),
              const SizedBox(height: 18),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _roleChip('👨‍🌾 Farmer', AppConstants.roleFarmer),
                  _roleChip('🚚 Transporter', AppConstants.roleTransporter),
                  _roleChip('🏭 Warehouse', AppConstants.roleWarehouseManager),
                  _roleChip('🛒 Buyer', AppConstants.roleBuyer),
                  _roleChip('⚡ Admin', AppConstants.roleAdmin),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String label, String role) {
    return ActionChip(
      backgroundColor: AppTheme.darkSurface,
      side: const BorderSide(color: AppTheme.darkBorder),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      onPressed: () => _handleLogin(role),
    );
  }
}
