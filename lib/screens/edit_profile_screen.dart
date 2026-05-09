import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_button.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  String? _selectedAvatar;
  
  // Medieval/Adventurer style avatars
  final List<String> _avatars = [
    'https://api.dicebear.com/7.x/adventurer/png?seed=Knight',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Witch',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Wolf',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Mage',
    'https://api.dicebear.com/7.x/adventurer/png?seed=King',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Villager',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Ranger',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Blacksmith',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Healer',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _selectedAvatar = user?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<UserProvider>().t('enter_name_error'))),
      );
      return;
    }
    
    await context.read<UserProvider>().updateName(name);
    
    if (_selectedAvatar != null) {
      await context.read<UserProvider>().updateAvatar(_selectedAvatar!);
    }
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final leather = AppTheme.leatherBrown;
    final surface = AppTheme.daySurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(userProvider.t('edit_profile')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMedievalCard(
              color: leather,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    userProvider.t('nickname'), 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.face),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildMedievalCard(
              color: surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(userProvider.t('choose_avatar'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.dayText)),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: _avatars.length,
                    itemBuilder: (context, index) {
                      final avatar = _avatars[index];
                      final isSelected = _selectedAvatar == avatar;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _selectedAvatar = avatar;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.goldBorder.withOpacity(0.3) : Colors.white.withOpacity(0.5),
                            border: Border.all(
                              color: isSelected ? AppTheme.goldBorder : Colors.transparent,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                avatar,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.person),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: userProvider.t('save_changes'),
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedievalCard({required Widget child, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.goldBorder, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(6, 6),
            blurRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }
}
