import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';
import '../theme/app_theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    if (_nameController.text.trim().isEmpty) {
      final up = context.read<UserProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(up.t('enter_nickname_error'))),
      );
      return;
    }

    setState(() => _isLoading = true);
    await context.read<UserProvider>().setupProfile(_nameController.text.trim());
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userProvider.t('welcome_title'),
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  userProvider.t('nickname_prompt'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 60),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: userProvider.t('nickname_label'),
                    prefixIcon: const Icon(Icons.face),
                  ),
                ),
                const SizedBox(height: 40),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: userProvider.t('enter_game'),
                      onPressed: _submit,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
