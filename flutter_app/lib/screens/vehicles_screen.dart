import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../repositories/vehicle_repository.dart';
import '../repositories/customer_repository.dart';
import '../screens/customers_screen.dart'; // For Customer class

class Vehicle {
  final String id;
  final String number;
  final String model;
  final String year;
  final String owner;
  final String color;
  final String fuelType;
  final String lastService;
  final int totalServices;
  final String status;

  Vehicle({
    required this.id,
    required this.number,
    required this.model,
    required this.year,
    required this.owner,
    required this.color,
    required this.fuelType,
    required this.lastService,
    required this.totalServices,
    required this.status,
  });
}

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

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
              StreamBuilder<List<Vehicle>>(
                stream: Supabase.instance.client
                  .from('vehicles')
                  .stream(primaryKey: ['id'])
                  .order('number', ascending: true)
                  .map((data) => data.map((json) => Vehicle(
                    id: json['id'],
                    number: json['number'],
                    model: json['model'] ?? '',
                    year: json['year'] ?? '',
                    owner: '', // Requires customer fetch or join
                    color: json['color'] ?? '',
                    fuelType: json['fuel_type'] ?? '',
                    lastService: json['last_service'] != null
                        ? DateTime.tryParse(json['last_service'].toString())?.toLocal().toString().split(' ')[0] ?? 'N/A'
                        : 'N/A',
                    totalServices: json['total_services'] ?? 0,
                    status: json['status'] ?? 'active',
                  )).toList()),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final vehicles = snapshot.data!;
                  if (vehicles.isEmpty) {
                    return const Center(child: Text('No vehicles found'));
                  }
                  return _buildVehiclesList(vehicles);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVehicleDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Add Vehicle'),
      ),
    );
  }

  Future<void> _showAddVehicleDialog(BuildContext context) async {
    final numberController = TextEditingController();
    final modelController = TextEditingController();
    final yearController = TextEditingController();
    final colorController = TextEditingController();
    final fuelController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedCustomerId;

    // Fetch customers
    final customerRepo = CustomerRepository();
    // Note: getCustomers returns a Stream, we get the first element for the dropdown
    // Ideally this should use a Future-based fetch for specific simple lists, but we can take first from stream
    List<Customer> customers = [];
    try {
      customers = await customerRepo.getCustomers().first;
    } catch (e) {
      debugPrint('Error fetching customers: $e');
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // Use StatefulBuilder to update dropdown state
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text('Add New Vehicle', style: TextStyle(color: AppColors.foreground)),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        dropdownColor: AppColors.card,
                        decoration: const InputDecoration(labelText: 'Owner', labelStyle: TextStyle(color: AppColors.mutedForeground)),
                        style: const TextStyle(color: AppColors.foreground),
                        items: customers.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, style: const TextStyle(color: AppColors.foreground)),
                        )).toList(),
                        onChanged: (val) => setState(() => selectedCustomerId = val),
                        validator: (val) => val == null ? 'Owner is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: numberController,
                        decoration: const InputDecoration(labelText: 'Vehicle Number', labelStyle: TextStyle(color: AppColors.mutedForeground)),
                        style: const TextStyle(color: AppColors.foreground),
                        validator: (value) => value?.isEmpty ?? true ? 'Number is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: modelController,
                        decoration: const InputDecoration(labelText: 'Model', labelStyle: TextStyle(color: AppColors.mutedForeground)),
                        style: const TextStyle(color: AppColors.foreground),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: yearController,
                        decoration: const InputDecoration(labelText: 'Year', labelStyle: TextStyle(color: AppColors.mutedForeground)),
                        style: const TextStyle(color: AppColors.foreground),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: colorController,
                        decoration: const InputDecoration(labelText: 'Color', labelStyle: TextStyle(color: AppColors.mutedForeground)),
                        style: const TextStyle(color: AppColors.foreground),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: fuelController,
                        decoration: const InputDecoration(labelText: 'Fuel Type', labelStyle: TextStyle(color: AppColors.mutedForeground)),
                        style: const TextStyle(color: AppColors.foreground),
                      ),
                    ],
                  ),
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
                      await VehicleRepository().addVehicle({
                        'customer_id': selectedCustomerId,
                        'number': numberController.text,
                        'model': modelController.text,
                        'year': yearController.text,
                        'color': colorController.text,
                        'fuel_type': fuelController.text,
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vehicle added successfully!')),
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
          );
        }
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicles',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
        const SizedBox(height: 4),
        const Text(
          'Track all registered vehicles and history',
          style: TextStyle(color: AppColors.mutedForeground),
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search vehicles...',
        prefixIcon: const Icon(LucideIcons.search, size: 20, color: AppColors.mutedForeground),
        fillColor: AppColors.secondary,
      ),
    );
  }

  Widget _buildVehiclesList(List<Vehicle> vehicles) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vehicles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        final isInService = vehicle.status == 'in-service';

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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.car, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vehicle.number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${vehicle.model} • ${vehicle.year}', style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                        ],
                      ),
                    ],
                  ),
                  _buildStatusBadge(isInService),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Owner', style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                      Text(vehicle.owner, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  Row(
                    children: [
                      _buildInfoTag(vehicle.color),
                      const SizedBox(width: 8),
                      _buildInfoTag(vehicle.fuelType),
                    ],
                  ),
                ],
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
                        const Text('Last Service', style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                        Row(
                          children: [
                            const Icon(LucideIcons.calendar, size: 12, color: AppColors.mutedForeground),
                            const SizedBox(width: 4),
                            Text(vehicle.lastService, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Total Services', style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                        Row(
                          children: [
                            const Icon(LucideIcons.wrench, size: 12, color: AppColors.mutedForeground),
                            const SizedBox(width: 4),
                            Text('${vehicle.totalServices} times', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
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

  Widget _buildStatusBadge(bool isInService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isInService ? AppColors.warning : AppColors.success).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isInService ? 'In Service' : 'Active',
        style: TextStyle(
          color: isInService ? AppColors.warning : AppColors.success,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
    );
  }
}
