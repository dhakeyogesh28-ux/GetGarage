import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dashboard_screen.dart';
import 'jobs_screen.dart';
import 'vehicles_screen.dart';
import 'customers_screen.dart';
import 'inventory_screen.dart';
import 'khatabook_screen.dart';
import 'estimates_screen.dart';
import 'settings_screen.dart';
import '../theme/app_colors.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const JobsScreen(),
    const VehiclesScreen(),
    const CustomersScreen(),
    const InventoryScreen(),
    const KhatabookScreen(),
    const EstimatesScreen(),
    const SettingsScreen(),
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': LucideIcons.layoutDashboard, 'label': 'Dashboard'},
    {'icon': LucideIcons.wrench, 'label': 'Jobs'},
    {'icon': LucideIcons.car, 'label': 'Vehicles'},
    {'icon': LucideIcons.users, 'label': 'Customers'},
    {'icon': LucideIcons.package, 'label': 'Inventory'},
    {'icon': LucideIcons.book, 'label': 'Khatabook'},
    {'icon': LucideIcons.fileText, 'label': 'Estimates'},
    {'icon': LucideIcons.settings, 'label': 'Settings'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(LucideIcons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(_menuItems[_selectedIndex]['label']),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.sidebarBackground,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(LucideIcons.car, color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'GetGarage',
                      style: TextStyle(
                        color: AppColors.foreground,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Space Grotesk',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  final isSelected = _selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        Navigator.pop(context);
                      },
                      leading: Icon(
                        item['icon'],
                        color: isSelected ? AppColors.primary : AppColors.mutedForeground,
                        size: 20,
                      ),
                      title: Text(
                        item['label'],
                        style: TextStyle(
                          color: isSelected ? AppColors.foreground : AppColors.mutedForeground,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: AppColors.primary.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}
