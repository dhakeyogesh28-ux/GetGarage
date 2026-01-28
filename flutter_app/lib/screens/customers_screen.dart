import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../repositories/customer_repository.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final List<String> vehicles;
  final double totalSpent;
  final String lastVisit;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.vehicles,
    required this.totalSpent,
    required this.lastVisit,
  });
}

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

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
              _buildSearchBox(),
              const SizedBox(height: 24),
              StreamBuilder<List<Customer>>(
                stream: Supabase.instance.client
                  .from('customers')
                  .stream(primaryKey: ['id'])
                  .order('name', ascending: true)
                  .map((data) => data.map((json) => Customer(
                    id: json['id'],
                    name: json['name'],
                    phone: json['phone'] ?? '',
                    email: json['email'] ?? '',
                    address: json['address'] ?? '',
                    vehicles: [], // Add vehicle fetching logic if needed
                    totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
                    lastVisit: json['last_visit'] != null 
                        ? DateTime.tryParse(json['last_visit'].toString())?.toLocal().toString().split(' ')[0] ?? 'N/A' 
                        : 'N/A',
                  )).toList()),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final customers = snapshot.data!;
                  if (customers.isEmpty) {
                    return const Center(child: Text('No customers found'));
                  }
                  return _buildCustomersList(customers);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        icon: const Icon(LucideIcons.userPlus),
        label: const Text('Add Customer'),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Add New Customer', style: TextStyle(color: AppColors.foreground)),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: AppColors.mutedForeground)),
                  style: const TextStyle(color: AppColors.foreground),
                  validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone', labelStyle: TextStyle(color: AppColors.mutedForeground)),
                   style: const TextStyle(color: AppColors.foreground),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: AppColors.mutedForeground)),
                   style: const TextStyle(color: AppColors.foreground),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address', labelStyle: TextStyle(color: AppColors.mutedForeground)),
                   style: const TextStyle(color: AppColors.foreground),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedForeground)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  await CustomerRepository().addCustomer({
                    'name': nameController.text,
                    'phone': phoneController.text,
                    'email': emailController.text,
                    'address': addressController.text,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Customer added successfully!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.destructive),
                    );
                  }
                }
              }
            },
            child: const Text('Add', style: TextStyle(color: AppColors.primaryForeground)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customers',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
        const SizedBox(height: 4),
        const Text(
          'Manage your customer database',
          style: TextStyle(color: AppColors.mutedForeground),
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search customers...',
        prefixIcon: const Icon(LucideIcons.search, size: 20, color: AppColors.mutedForeground),
        fillColor: AppColors.secondary,
      ),
    );
  }

  Widget _buildCustomersList(List<Customer> customers) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: customers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final customer = customers[index];
        final initials = customer.name.split(' ').map((n) => n[0]).join('').toUpperCase();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Last visit: ${customer.lastVisit}', style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.moreVertical, size: 18),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildContactItem(LucideIcons.phone, customer.phone),
              const SizedBox(height: 8),
              _buildContactItem(LucideIcons.mail, customer.email),
              const SizedBox(height: 8),
              _buildContactItem(LucideIcons.mapPin, customer.address),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: customer.vehicles.map((v) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(v, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                )).toList(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.3))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Spent', style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                        Text(
                          '₹${NumberFormat('#,##,###').format(customer.totalSpent)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(LucideIcons.messageSquare, size: 16, color: AppColors.success),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        side: BorderSide(color: AppColors.border.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.mutedForeground),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
      ],
    );
  }
}
