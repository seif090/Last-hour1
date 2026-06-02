import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';

class MerchantRegistrationPage extends StatefulWidget {
  const MerchantRegistrationPage({super.key});

  @override
  State<MerchantRegistrationPage> createState() => _MerchantRegistrationPageState();
}

class _MerchantRegistrationPageState extends State<MerchantRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  String _businessType = 'restaurant';

  final _businessTypes = ['restaurant', 'bakery', 'supermarket', 'cafe', 'other'];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _businessNameCtrl.dispose();
    _descCtrl.dispose();
    _taxIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register as Merchant')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v != null && v.contains('@') ? null : 'Valid email required',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outlined), border: OutlineInputBorder()),
                obscureText: true,
                validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 characters',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _businessNameCtrl,
                decoration: const InputDecoration(labelText: 'Business Name', prefixIcon: Icon(Icons.store), border: OutlineInputBorder()),
                validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Business name required',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _businessType,
                decoration: const InputDecoration(labelText: 'Business Type', prefixIcon: Icon(Icons.category), border: OutlineInputBorder()),
                items: _businessTypes.map((t) => DropdownMenuItem(value: t, child: Text(t[0].toUpperCase() + t.substring(1)))).toList(),
                onChanged: (v) => setState(() => _businessType = v ?? 'restaurant'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _taxIdCtrl,
                decoration: const InputDecoration(labelText: 'Tax ID (optional)', prefixIcon: Icon(Icons.receipt), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 32),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      context.read<AuthBloc>().add(RegisterRequested(
                        email: _emailCtrl.text.trim(),
                        password: _passCtrl.text,
                        businessName: _businessNameCtrl.text.trim(),
                        businessType: _businessType,
                        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
                        taxId: _taxIdCtrl.text.trim().isEmpty ? null : _taxIdCtrl.text.trim(),
                      ));
                    },
                    child: state is AuthLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Register'),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Already have an account? Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
