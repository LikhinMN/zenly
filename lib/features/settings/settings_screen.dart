import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _openKeyboardSettings() async {
    try {
      await const MethodChannel('com.likhinmn.zenly/ime_prefs')
          .invokeMethod('openIMESettings');
    } catch (e) {
      debugPrint('Could not open IME settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionTitle(theme, 'API Keys'),
          _buildSettingCard(
            theme,
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.key_outlined,
                  title: 'Groq API Key',
                  subtitle: 'Managed via .env file',
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Gemini API Key',
                  subtitle: 'Managed via .env file',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          _buildSectionTitle(theme, 'System Keyboard'),
          _buildSettingCard(
            theme,
            child: _buildListTile(
              icon: Icons.keyboard_alt_outlined,
              title: 'Zenly Voice Keyboard',
              subtitle: 'Tap to manage in Android Settings',
              onTap: _openKeyboardSettings,
            ),
          ),
          
          const SizedBox(height: 64),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.mic, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Zenly',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingCard(ThemeData theme, {required Widget child}) {
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withAlpha(26)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      onTap: onTap,
      trailing: onTap != null ? Icon(Icons.chevron_right, color: Colors.grey.shade400) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
