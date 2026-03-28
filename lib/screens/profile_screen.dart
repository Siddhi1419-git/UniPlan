import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import '../providers/theme_provider.dart';
import '../services/cache_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final CacheService _cache = CacheService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    final syncTime = await _cache.getLastSyncTime();
    setState(() {
      _lastSyncTime = syncTime;
    });
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _db.ref('users/${user.uid}').get();
      if (snapshot.exists && snapshot.value != null) {
        setState(() {
          _userData = Map<String, dynamic>.from(snapshot.value as Map);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (user != null) ...[
                    Text(
                      user.email ?? 'No email',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_userData != null) ...[
                      Chip(
                        label: Text(
                          _userData!['role']?.toString().toUpperCase() ?? 'USER',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.blue.shade50,
                      ),
                      const SizedBox(height: 24),
                      if (_userData!['role'] == 'student') ...[
                        _buildInfoTile(
                          'Semester',
                          _userData!['semesterId']?.toString() ?? 'N/A',
                          Icons.school,
                        ),
                        _buildInfoTile(
                          'Division',
                          _userData!['divisionId']?.toString() ?? 'N/A',
                          Icons.group,
                        ),
                      ] else if (_userData!['role'] == 'faculty') ...[
                        _buildInfoTile(
                          'Teacher ID',
                          _userData!['teacherId']?.toString() ?? 'N/A',
                          Icons.badge,
                        ),
                      ],
                    ],
                  ],
                  const SizedBox(height: 24),
                  // Last Sync Time
                  if (_lastSyncTime != null)
                    Card(
                      color: Colors.green.shade50,
                      child: ListTile(
                        leading: Icon(Icons.cloud_done, color: Colors.green.shade700),
                        title: const Text('Last Synced'),
                        subtitle: Text(
                          _formatDateTime(_lastSyncTime!),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Dark Mode Toggle
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.dark_mode,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Dark Mode'),
                      subtitle: Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) {
                          String modeText;
                          if (themeProvider.themeMode == ThemeMode.light) {
                            modeText = 'Light';
                          } else if (themeProvider.themeMode == ThemeMode.dark) {
                            modeText = 'Dark';
                          } else {
                            modeText = 'System';
                          }
                          return Text('Current: $modeText');
                        },
                      ),
                      trailing: Consumer<ThemeProvider>(
                        builder: (context, themeProvider, _) {
                          return Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (_) => themeProvider.toggleTheme(),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
