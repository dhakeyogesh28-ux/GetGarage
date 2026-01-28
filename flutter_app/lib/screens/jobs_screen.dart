import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/job_card.dart';
import '../theme/app_colors.dart';
import '../repositories/job_repository.dart';
import '../repositories/vehicle_repository.dart';
import '../screens/vehicles_screen.dart'; // For Vehicle class
import 'package:supabase_flutter/supabase_flutter.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jobs = [
      {
        'id': 'JC-001',
        'vehicleNumber': 'MH 12 AB 1234',
        'vehicleModel': 'Honda City 2020',
        'customerName': 'Rajesh Kumar',
        'customerPhone': '+91 98765 43210',
        'description': 'Full service with oil change, brake pad replacement, and AC servicing',
        'status': JobStatus.inProgress,
        'createdAt': '2 hours ago',
        'estimatedAmount': 8500.0,
      },
      {
        'id': 'JC-002',
        'vehicleNumber': 'MH 14 CD 5678',
        'vehicleModel': 'Maruti Swift',
        'customerName': 'Priya Sharma',
        'customerPhone': '+91 87654 32109',
        'description': 'Engine overheating issue diagnosis and repair',
        'status': JobStatus.booked,
        'createdAt': '5 hours ago',
        'estimatedAmount': 3500.0,
      },
      {
        'id': 'JC-003',
        'vehicleNumber': 'MH 01 EF 9012',
        'vehicleModel': 'Hyundai Creta',
        'customerName': 'Amit Patel',
        'customerPhone': '+91 76543 21098',
        'description': 'Clutch plate replacement and gear box servicing',
        'status': JobStatus.completed,
        'createdAt': 'Yesterday',
        'estimatedAmount': 15000.0,
      },
      {
        'id': 'JC-004',
        'vehicleNumber': 'MH 02 XY 5566',
        'vehicleModel': 'Toyota Fortuner',
        'customerName': 'Suresh Raina',
        'customerPhone': '+91 99999 88888',
        'description': 'Routine maintenance and wheel balancing',
        'status': JobStatus.delivered,
        'createdAt': '2 days ago',
        'estimatedAmount': 12000.0,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.filter),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(LucideIcons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: JobRepository().getJobs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
           if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final jobs = snapshot.data ?? [];
          if (jobs.isEmpty) {
            return const Center(child: Text('No jobs found'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final job = jobs[index];
              final vehicle = job['vehicles'];
              final customer = job['customers'];

              return JobCard(
                id: (job['id'] ?? '').toString().split('-').first.toUpperCase(), // Shorten UUID
                vehicleNumber: vehicle?['number'] ?? 'Unknown',
                vehicleModel: vehicle?['model'] ?? 'Unknown',
                customerName: customer?['name'] ?? 'Unknown',
                customerPhone: customer?['phone'] ?? '',
                description: job['description'] ?? '',
                status: _parseStatus(job['status']),
                createdAt: job['created_at'] != null 
                    ? DateTime.parse(job['created_at']).toString().split(' ')[0] 
                    : '',
                estimatedAmount: (job['estimated_amount'] as num?)?.toDouble(),
              ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
         onPressed: () => _showAddJobDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Add Job'),
      ),
    );
  }

  JobStatus _parseStatus(String? status) {
    switch (status) {
      case 'in-progress': return JobStatus.inProgress;
      case 'completed': return JobStatus.completed;
      case 'delivered': return JobStatus.delivered;
      default: return JobStatus.booked;
    }
  }

  Future<void> _showAddJobDialog(BuildContext context) async {
    final descriptionController = TextEditingController();
    final estimateController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedVehicleId;
    String? selectedCustomerId;

    // Fetch vehicles for dropdown (and their owners)
    // Simplification: We select a vehicle, and that gives us the customer_id implicitly or explicitly
    final vehicleRepo = VehicleRepository();
    // We need to fetch vehicles AND their customer_id. 
    // The simple `getVehicles` returns Vehicle objects which might not have customer_id populated nicely if it was just 'owner' string name.
    // Let's assume we can get a list of vehicles and we'll just store vehicle_id.
    // But we also need customer_id for the jobs table.
    // We will do a direct select here for the dropdown to get both.
    List<Map<String, dynamic>> vehicles = [];
    try {
      final response = await Supabase.instance.client
          .from('vehicles')
          .select('id, number, model, customer_id, customers(name)');
      vehicles = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error: $e');
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text('New Job Card', style: TextStyle(color: AppColors.foreground)),
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
                        decoration: const InputDecoration(labelText: 'Select Vehicle', labelStyle: TextStyle(color: AppColors.mutedForeground)),
                        style: const TextStyle(color: AppColors.foreground),
                        items: vehicles.map((v) {
                          final customerName = v['customers']?['name'] ?? 'Unknown';
                          return DropdownMenuItem(
                            value: v['id'] as String,
                            child: Text('${v['number']} ($customerName)', style: const TextStyle(color: AppColors.foreground)),
                            onTap: () {
                              selectedCustomerId = v['customer_id'];
                            },
                          );
                        }).toList(),
                        onChanged: (val) {
                           setState(() {
                             selectedVehicleId = val;
                             // Find the vehicle to set customer id
                             final v = vehicles.firstWhere((element) => element['id'] == val);
                             selectedCustomerId = v['customer_id'];
                           });
                        },
                        validator: (val) => val == null ? 'Vehicle is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: AppColors.mutedForeground)),
                         style: const TextStyle(color: AppColors.foreground),
                        maxLines: 3,
                        validator: (v) => v?.isEmpty ?? true ? 'Description is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: estimateController,
                        decoration: const InputDecoration(labelText: 'Estimated Amount', labelStyle: TextStyle(color: AppColors.mutedForeground)),
                         style: const TextStyle(color: AppColors.foreground),
                        keyboardType: TextInputType.number,
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
                     if (selectedVehicleId == null || selectedCustomerId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a vehicle with a valid owner')));
                        return;
                     }
                    try {
                      await JobRepository().addJob({
                        'vehicle_id': selectedVehicleId,
                        'customer_id': selectedCustomerId,
                        'description': descriptionController.text,
                        'estimated_amount': double.tryParse(estimateController.text) ?? 0,
                        'status': 'booked',
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Job created successfully!')),
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
                child: const Text('Create Job', style: TextStyle(color: AppColors.primaryForeground)),
              ),
            ],
          );
        }
      ),
    );
  }
}
