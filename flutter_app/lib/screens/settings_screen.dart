import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildGarageProfile(context),
              const SizedBox(height: 24),
              _buildNotifications(context),
              const SizedBox(height: 24),
              _buildMoreSettingsGrid(context),
              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Logout', style: TextStyle(color: AppColors.destructive, fontWeight: FontWeight.bold)),
                ),
              ),
              const Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
        const SizedBox(height: 4),
        const Text(
          'Manage your garage profile and preferences',
          style: TextStyle(color: AppColors.mutedForeground),
        ),
      ],
    );
  }

  Widget _buildGarageProfile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.building2, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Garage Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text('Basic information about your garage', style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInput('Garage Name', 'AutoCare Workshop'),
          const SizedBox(height: 16),
          _buildInput('GST Number', '27AABCU9603R1ZM'),
          const SizedBox(height: 16),
          _buildInput('Address', '123, Industrial Area, Pune, Maharashtra - 411001'),
          const SizedBox(height: 16),
          _buildInput('Phone Number', '+91 98765 43210'),
          const SizedBox(height: 16),
          _buildInput('Email', 'contact@autocare.com'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 44),
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildInput(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.mutedForeground)),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildNotifications(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.bell, color: AppColors.info, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text('Configure how you receive alerts', style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSwitchTile('Job Updates', 'Get notified when job status changes', true),
          const Divider(height: 1, color: AppColors.border),
          _buildSwitchTile('Low Stock Alerts', 'Alert when inventory falls below minimum', true),
          const Divider(height: 1, color: AppColors.border),
          _buildSwitchTile('Payment Reminders', 'Send payment reminders to customers', true),
          const Divider(height: 1, color: AppColors.border),
          _buildSwitchTile('WhatsApp Messages', 'Enable WhatsApp notifications', false),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {},
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildMoreSettingsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildSettingCard('Staff Management', 'manage workers', LucideIcons.user, AppColors.success),
        _buildSettingCard('Security', 'password & login', LucideIcons.shield, AppColors.warning),
        _buildSettingCard('Payment Settings', 'bank & QR info', LucideIcons.creditCard, AppColors.primary),
        _buildSettingCard('Help & Support', 'get assistance', LucideIcons.helpCircle, AppColors.mutedForeground),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildSettingCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
