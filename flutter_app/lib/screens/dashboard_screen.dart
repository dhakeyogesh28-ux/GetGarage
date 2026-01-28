import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/metric_card.dart';
import '../widgets/job_card.dart';
import '../theme/app_colors.dart';
import '../repositories/job_repository.dart';
import 'jobs_screen.dart'; // To navigate/use status enum
import 'add_service_screen.dart';
import 'package:go_router/go_router.dart'; // If using router
import 'package:supabase_flutter/supabase_flutter.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
              const SizedBox(height: 32),
              _buildRecentJobsHeader(context),
              const SizedBox(height: 16),
              _buildRecentJobsList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddServiceScreen())),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        icon: const Icon(LucideIcons.plusCircle),
        label: const Text('Add Service'),
      ).animate().scale(delay: 500.ms, curve: Curves.bounceOut),
    );
  }

  Future<void> _showAddJobDialog(BuildContext context) async {
    final descriptionController = TextEditingController();
    final estimateController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedVehicleId;
    String? selectedCustomerId;

    // Fetch vehicles for dropdown
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
                        items: vehicles.where((v) => v['customers'] != null).map((v) {
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

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning! 👋',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                  const SizedBox(height: 4),
                  Text(
                    "Here's what's happening at your garage today",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {},
              icon: Stack(
                children: [
                  const Icon(LucideIcons.bell, size: 24),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search jobs, customers...',
            prefixIcon: const Icon(LucideIcons.search, size: 20, color: AppColors.mutedForeground),
            fillColor: AppColors.secondary,
          ),
        ),
      ],
    );
  }





  Widget _buildRecentJobsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Jobs',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        TextButton(
          onPressed: () {},
          child: const Row(
            children: [
              Text('View All', style: TextStyle(color: AppColors.primary)),
              SizedBox(width: 4),
              Icon(LucideIcons.trendingUp, size: 14, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentJobsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: JobRepository().getJobs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(); // Loading handled silently or shimmer
        final jobs = snapshot.data!.take(3).toList(); // Show only 3 recent

         return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: jobs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final job = jobs[index];
            final vehicle = job['vehicles'];
            final customer = job['customers'];

            // Parse status safely
            JobStatus status = JobStatus.booked;
             switch (job['status']) {
              case 'in-progress': status = JobStatus.inProgress; break;
              case 'completed': status = JobStatus.completed; break;
              case 'delivered': status = JobStatus.delivered; break;
            }

            return JobCard(
              id: (job['id'] ?? '').toString().split('-').first.toUpperCase(),
              vehicleNumber: vehicle?['number'] ?? 'Unknown',
              vehicleModel: vehicle?['model'] ?? 'Unknown',
              customerName: customer?['name'] ?? 'Unknown',
              customerPhone: customer?['phone'] ?? '',
              description: job['description'] ?? '',
              status: status,
              createdAt: job['created_at'] != null 
                    ? DateTime.parse(job['created_at']).toString().split(' ')[0] 
                    : '',
              estimatedAmount: (job['estimated_amount'] as num?)?.toDouble(),
            ).animate().fadeIn(delay: (index * 100).ms);
          },
        );
      }
    );
  }
}
