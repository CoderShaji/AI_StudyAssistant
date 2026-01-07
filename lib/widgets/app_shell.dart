import 'package:flutter/material.dart';
import '../state/subject_provider.dart';
import '../state/theme_provider.dart';
import '../screens/home_screen.dart';
import '../pages/auth_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class AppShell extends StatefulWidget {
  final Widget child;
  final String title;
  final Subject? subject;
  const AppShell({Key? key, required this.child, this.title = '', this.subject}) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      if (user == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthPage()));
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: isDark ? AppColors.grey900 : AppColors.white,
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.orange500, AppColors.orange700],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.school, color: AppColors.white, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'AI Flashcard',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Learn Smarter',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings placeholder')),
                  ),
                ),
                _DrawerItem(
                  icon: Icons.text_snippet_outlined,
                  title: 'Extract Text',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Extract placeholder')),
                  ),
                ),
                _DrawerItem(
                  icon: Icons.storage_outlined,
                  title: 'Storage',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Storage placeholder')),
                  ),
                ),
                const Divider(height: 1),
                _DrawerItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help placeholder')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                ? [AppColors.grey900, AppColors.grey800]
                : [AppColors.orange500, AppColors.orange700],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Builder(builder: (ctx) {
                  final canPop = Navigator.of(ctx).canPop();
                  if (!canPop) {
                    return IconButton(
                      icon: const Icon(Icons.menu),
                      tooltip: 'Menu',
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                      color: AppColors.white,
                    );
                  }
                  return IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(ctx).maybePop(),
                    color: AppColors.white,
                  );
                }),
                IconButton(
                  icon: const Icon(Icons.home_outlined),
                  tooltip: 'Home',
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    HomeScreen.routeName,
                    (route) => false,
                  ),
                  color: AppColors.white,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      widget.title.isNotEmpty ? widget.title : 'AI Flashcard',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                  icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                  onPressed: () => themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark,
                  color: AppColors.white,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.white),
                  onSelected: (value) async {
                    if (value == 'logout') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Sign out'),
                          content: const Text('Are you sure you want to sign out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Sign out'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          await FirebaseAuth.instance.signOut();
                        } catch (e) {
                          // ignore errors
                        }
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          HomeScreen.routeName,
                          (r) => false,
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 12),
                          Text('Sign Out'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(child: widget.child),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: isDark ? AppColors.orange400 : AppColors.orange600),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}