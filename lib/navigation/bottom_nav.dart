import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/home_screen.dart';
import '../screens/semester_selection_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/notifications_screen.dart';
import '../widgets/offline_indicator.dart';
import '../services/firebase_service.dart';

class BottomNav extends StatefulWidget {
  final String? semesterId;
  final String? divisionId;

  const BottomNav({
    super.key,
    this.semesterId,
    this.divisionId,
  });

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;

  late final List<Widget> _screens;
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        semesterId: widget.semesterId,
        divisionId: widget.divisionId,
      ),
      SemesterSelectionScreen(),
      NotificationsScreen(
        semesterId: widget.semesterId,
        divisionId: widget.divisionId,
      ),
      ProfileScreen(),
    ];
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final items = await _firebaseService.getAnnouncementsForUser(
        user.uid,
        widget.semesterId ?? '',
        widget.divisionId ?? '',
      );
      if (!mounted) return;
      setState(() {
        _notificationCount = items.length;
      });
    } catch (_) {
      // Ignore count errors; don't break UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 2) {
            // When user opens Notifications tab, refresh count
            _loadNotificationCount();
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Timetable',
          ),
          NavigationDestination(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications),
                if (_notificationCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          _notificationCount > 9
                              ? '9+'
                              : _notificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Notifications',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
