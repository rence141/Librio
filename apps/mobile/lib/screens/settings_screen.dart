import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onThemeChanged;

  const SettingsScreen({super.key, this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SharedPreferences _prefs;
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _analyticsEnabled = true;
  bool _dataCollectionEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDarkMode = _prefs.getBool('darkMode') ?? false;
        _notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? true;
        _analyticsEnabled = _prefs.getBool('analyticsEnabled') ?? true;
        _dataCollectionEnabled = _prefs.getBool('dataCollectionEnabled') ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is String) {
        await _prefs.setString(key, value);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save setting: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings', style: TextStyle(fontFamily: 'Fredoka')),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontFamily: 'Fredoka')),
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        children: [
          // Theme Section
          _buildSectionHeader('Appearance'),
          _buildThemeCard(),
          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildNotificationCard(),
          const SizedBox(height: 24),

          // Privacy Section
          _buildSectionHeader('Privacy & Data'),
          _buildPrivacyCard(),
          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          _buildAboutCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontFamily: 'Fredoka',
        ),
      ),
    );
  }

  Widget _buildThemeCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: isDark ? Colors.amber : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Dark Mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Fredoka',
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _isDarkMode,
                  onChanged: (value) async {
                    setState(() {
                      _isDarkMode = value;
                    });
                    await _saveSetting('darkMode', value);
                    // Notify parent to update theme after saving
                    await Future.delayed(const Duration(milliseconds: 100));
                    widget.onThemeChanged?.call();
                  },
                  activeColor: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Use dark theme for a comfortable viewing experience in low light',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                fontFamily: 'Fredoka',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Push Notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Fredoka',
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    _saveSetting('notificationsEnabled', value);
                  },
                  activeColor: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Receive notifications for study reminders and updates',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                fontFamily: 'Fredoka',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Analytics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Fredoka',
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _analyticsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _analyticsEnabled = value;
                    });
                    _saveSetting('analyticsEnabled', value);
                  },
                  activeColor: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lock_outlined,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Data Collection',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Fredoka',
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _dataCollectionEnabled,
                  onChanged: (value) {
                    setState(() {
                      _dataCollectionEnabled = value;
                    });
                    _saveSetting('dataCollectionEnabled', value);
                  },
                  activeColor: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Allow collection of study data for personalization',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                fontFamily: 'Fredoka',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Librio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Fredoka',
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontFamily: 'Fredoka',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your AI study companion for smarter learning',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                fontFamily: 'Fredoka',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
