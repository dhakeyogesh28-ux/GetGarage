import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_garage/theme/app_colors.dart';
import 'package:get_garage/repositories/customer_repository.dart';
import 'package:get_garage/repositories/vehicle_repository.dart';
import 'package:get_garage/repositories/job_repository.dart';
import 'package:get_garage/screens/customers_screen.dart'; // For Customer class
import 'package:get_garage/screens/vehicles_screen.dart'; // For Vehicle class
import 'package:get_garage/services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

// Reuse EstimateItem logic but simplified for this screen
class ServiceEstimateItem {
  String id;
  String type;
  TextEditingController descriptionController;
  TextEditingController quantityController;
  TextEditingController unitPriceController;

  ServiceEstimateItem({
    required this.id,
    this.type = 'labor',
  }) : descriptionController = TextEditingController(),
       quantityController = TextEditingController(text: '1'),
       unitPriceController = TextEditingController(text: '0');

  double get total => (int.tryParse(quantityController.text) ?? 0) * (double.tryParse(unitPriceController.text) ?? 0);

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
  }
}

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  
  // State for Step 1: Customer
  Customer? _selectedCustomer;
  final TextEditingController _customerSearchController = TextEditingController();
  String _customerSearchQuery = '';

  // State for Step 2: Vehicle
  Vehicle? _selectedVehicle;

  // State for Step 3: Job
  final TextEditingController _jobDescriptionController = TextEditingController();

  // State for Step 4: Estimate
  final List<ServiceEstimateItem> _estimateItems = [];

  @override
  void initState() {
    super.initState();
    _estimateItems.add(ServiceEstimateItem(id: DateTime.now().millisecondsSinceEpoch.toString()));
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    _jobDescriptionController.dispose();
    for (var item in _estimateItems) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 10),
            _buildStepper(),
            const SizedBox(height: 20),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                    child: child,
                  ));
                },
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              } else {
                Navigator.pop(context);
              }
            },
            icon: Icon(_currentStep > 0 ? LucideIcons.arrowLeft : LucideIcons.x, color: AppColors.mutedForeground),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Service',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                _getStepTitle(),
                style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (_isLoading) ...[
            const Spacer(),
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ]
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Step 1: Select Customer';
      case 1: return 'Step 2: Select Vehicle';
      case 2: return 'Step 3: Job & Items';
      case 3: return 'Step 4: Summary & Finish';
      default: return '';
    }
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Customer', LucideIcons.user),
          _buildConnector(0),
          _buildStepIndicator(1, 'Vehicle', LucideIcons.car),
          _buildConnector(1),
          _buildStepIndicator(2, 'Job', LucideIcons.wrench),
          _buildConnector(2),
          _buildStepIndicator(3, 'Estimate', LucideIcons.fileText),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.success : (isActive ? AppColors.primary : AppColors.secondary),
              shape: BoxShape.circle,
              boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)] : null,
            ),
            child: Icon(
              isCompleted ? LucideIcons.check : icon,
              color: (isActive || isCompleted) ? Colors.white : AppColors.mutedForeground,
              size: 16,
            ),
          ).animate(target: isActive ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 200.ms),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
              color: isActive || isCompleted ? AppColors.foreground : AppColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(int step) {
    final isCompleted = step < _currentStep;
    return Container(
      width: 15,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isCompleted ? AppColors.success : AppColors.border,
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildCustomerStep();
      case 1: return _buildVehicleStep();
      case 2: return _buildJobStep();
      case 3: return _buildEstimateStep();
      default: return const SizedBox();
    }
  }

  // --- STEP 1: CUSTOMER ---

  Widget _buildCustomerStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customerSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search name or phone...',
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    fillColor: AppColors.card,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (val) => setState(() => _customerSearchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: IconButton(
                  onPressed: () => _showAddCustomerDialog(context),
                  icon: const Icon(LucideIcons.userPlus, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Customer>>(
              stream: CustomerRepository().getCustomers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final customers = snapshot.data!.where((c) {
                  final q = _customerSearchQuery.toLowerCase();
                  return c.name.toLowerCase().contains(q) || c.phone.contains(q);
                }).toList();

                if (customers.isEmpty) {
                   return Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         const Icon(LucideIcons.users, size: 48, color: AppColors.mutedForeground),
                         const SizedBox(height: 16),
                         const Text('No customers found', style: TextStyle(color: AppColors.mutedForeground)),
                         const SizedBox(height: 12),
                         TextButton(onPressed: () => _showAddCustomerDialog(context), child: const Text('+ Add New Customer')),
                       ],
                     ),
                   );
                }

                return ListView.separated(
                  itemCount: customers.length,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    final isSelected = _selectedCustomer?.id == customer.id;
                    return InkWell(
                      onTap: () => setState(() => _selectedCustomer = customer),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border.withOpacity(0.5), width: isSelected ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isSelected ? AppColors.primary : AppColors.secondary,
                              child: Text(customer.name[0].toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : AppColors.foreground)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(customer.phone, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                                ],
                              ),
                            ),
                            if (isSelected) const Icon(LucideIcons.checkCircle2, color: AppColors.primary),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selectedCustomer != null ? () => setState(() => _currentStep++) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Next: Select Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(LucideIcons.chevronRight, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
      final nameController = TextEditingController();
      final phoneController = TextEditingController();
      final formKey = GlobalKey<FormState>();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('New Customer'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController, 
                  decoration: const InputDecoration(labelText: 'Full Name', hintText: 'e.g. John Doe'), 
                  validator: (v) => v!.isEmpty ? 'Required' : null
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController, 
                  decoration: const InputDecoration(labelText: 'Phone Number', hintText: 'e.g. 9876543210'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Required' : null
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  try {
                    setState(() => _isLoading = true);
                    final response = await Supabase.instance.client.from('customers').insert({
                      'name': nameController.text,
                      'phone': phoneController.text,
                    }).select().single();
                    
                    final newCustomer = Customer(
                      id: response['id'],
                      name: response['name'],
                      phone: response['phone'] ?? '',
                      email: response['email'] ?? '',
                      address: response['address'] ?? '',
                      vehicles: [],
                      totalSpent: 0,
                      lastVisit: 'N/A'
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      setState(() {
                         _selectedCustomer = newCustomer;
                         _isLoading = false;
                      });
                    }
                  } catch (e) {
                    setState(() => _isLoading = false);
                    debugPrint(e.toString());
                  }
                }
              },
              child: const Text('Add & Select'),
            ),
          ],
        ),
      );
  }


  // --- STEP 2: VEHICLE ---

  Widget _buildVehicleStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
           Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
             child: Row(
               children: [
                 const Icon(LucideIcons.user, size: 16, color: AppColors.primary),
                 const SizedBox(width: 8),
                 Text('Customer: ', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                 Text(_selectedCustomer?.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
               ],
             ),
           ),
           const SizedBox(height: 20),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               const Text('Select Vehicle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
               TextButton.icon(
                 onPressed: () => _showAddVehicleDialog(context), 
                 icon: const Icon(LucideIcons.plus, size: 16), 
                 label: const Text('Add New')
               ),
             ],
           ),
           const SizedBox(height: 12),
           Expanded(
            child: StreamBuilder<List<Vehicle>>(
              stream: Supabase.instance.client
                  .from('vehicles')
                  .stream(primaryKey: ['id'])
                  .eq('customer_id', _selectedCustomer!.id)
                  .map((data) => data.map((json) => Vehicle(
                    id: json['id'],
                    number: json['number'],
                    model: json['model'] ?? '',
                    year: json['year'] ?? '',
                    owner: _selectedCustomer!.name,
                    color: json['color'] ?? '',
                    fuelType: json['fuel_type'] ?? '',
                    lastService: 'N/A',
                    totalServices: json['total_services'] ?? 0,
                    status: json['status'] ?? 'active',
                  )).toList()),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final vehicles = snapshot.data!;

                if (vehicles.isEmpty) {
                   return Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         const Icon(LucideIcons.car, size: 48, color: AppColors.mutedForeground),
                         const SizedBox(height: 16),
                         const Text('No vehicles linked to this customer', style: TextStyle(color: AppColors.mutedForeground)),
                         const SizedBox(height: 12),
                         ElevatedButton.icon(
                           onPressed: () => _showAddVehicleDialog(context),
                           icon: const Icon(LucideIcons.plus),
                           label: const Text('Add First Vehicle'),
                           style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                         )
                       ],
                     ),
                   );
                }

                return ListView.separated(
                  itemCount: vehicles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    final isSelected = _selectedVehicle?.id == vehicle.id;
                    return InkWell(
                      onTap: () => setState(() => _selectedVehicle = vehicle),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border.withOpacity(0.5), width: isSelected ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: isSelected ? AppColors.primary : AppColors.secondary, borderRadius: BorderRadius.circular(12)),
                              child: Icon(LucideIcons.car, color: isSelected ? Colors.white : AppColors.mutedForeground, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(vehicle.number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('${vehicle.model} • ${vehicle.color}', style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                                ],
                              ),
                            ),
                            if (isSelected) const Icon(LucideIcons.checkCircle2, color: AppColors.primary),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
           const SizedBox(height: 16),
           ElevatedButton(
            onPressed: _selectedVehicle != null ? () => setState(() => _currentStep++) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, 
              foregroundColor: Colors.white, 
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Next: Job Details', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(LucideIcons.chevronRight, size: 18),
              ],
            ),
           ),
           const SizedBox(height: 20),
        ],
      )
    );
  }

  void _showAddVehicleDialog(BuildContext context) {
    if (_selectedCustomer == null) return;
    final numberController = TextEditingController();
    final modelController = TextEditingController();
    final colorController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vehicle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: numberController, decoration: const InputDecoration(labelText: 'Vehicle Number', hintText: 'MH 01 AB 1234'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: modelController, decoration: const InputDecoration(labelText: 'Model', hintText: 'Swift, City, etc.')),
              const SizedBox(height: 12),
              TextFormField(controller: colorController, decoration: const InputDecoration(labelText: 'Color')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                 try {
                   setState(() => _isLoading = true);
                   final response = await Supabase.instance.client.from('vehicles').insert({
                      'customer_id': _selectedCustomer!.id,
                      'number': numberController.text,
                      'model': modelController.text,
                      'color': colorController.text,
                   }).select().single();

                   final newVehicle = Vehicle(
                      id: response['id'],
                      number: response['number'],
                      model: response['model'] ?? '',
                      year: response['year'] ?? '',
                      owner: _selectedCustomer!.name,
                      color: response['color'] ?? '',
                      fuelType: response['fuel_type'] ?? '',
                      lastService: 'N/A',
                      totalServices: 0,
                      status: 'active',
                   );

                   if(context.mounted) {
                     Navigator.pop(context);
                     setState(() {
                        _selectedVehicle = newVehicle;
                        _isLoading = false;
                     });
                   }
                 } catch (e) {
                   setState(() => _isLoading = false);
                   debugPrint(e.toString());
                 }
              }
            },
            child: const Text('Add & Select'),
          )
        ],
      ),
    );
  }


  // --- STEP 3: JOB DETAILS ---

  Widget _buildJobStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
             child: Row(
               children: [
                 const Icon(LucideIcons.car, size: 14, color: AppColors.primary),
                 const SizedBox(width: 8),
                 Text('${_selectedVehicle?.number} (${_selectedVehicle?.model})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
               ],
             ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimate Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  ..._estimateItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.border.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(20)),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: item.type,
                                    isDense: true,
                                    style: const TextStyle(fontSize: 12, color: AppColors.foreground, fontWeight: FontWeight.bold),
                                    items: const [
                                      DropdownMenuItem(value: 'part', child: Text('PART')),
                                      DropdownMenuItem(value: 'labor', child: Text('LABOR')),
                                    ],
                                    onChanged: (v) => setState(() => item.type = v!),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (_estimateItems.length > 1)
                                IconButton(
                                  onPressed: () => setState(() => _estimateItems.removeAt(index)), 
                                  icon: const Icon(LucideIcons.trash2, color: AppColors.destructive, size: 18)
                                )
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: item.descriptionController,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              hintText: 'Item description...',
                              isDense: true,
                              border: InputBorder.none,
                              hintStyle: TextStyle(fontWeight: FontWeight.normal),
                            ),
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('QTY', style: TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
                                    TextField(
                                      controller: item.quantityController, 
                                      keyboardType: TextInputType.number, 
                                      decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                                      onChanged: (_) => setState((){}),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('UNIT PRICE', style: TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
                                    TextField(
                                      controller: item.unitPriceController, 
                                      keyboardType: TextInputType.number, 
                                      decoration: const InputDecoration(isDense: true, border: InputBorder.none, prefixText: '₹'),
                                      onChanged: (_) => setState((){}),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('TOTAL', style: TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
                                    Text('₹${item.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  }),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _estimateItems.add(ServiceEstimateItem(id: DateTime.now().millisecondsSinceEpoch.toString()));
                    }), 
                    icon: const Icon(LucideIcons.plus, size: 18), 
                    label: const Text('Add Another Item'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('What needs to be done?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _jobDescriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe general service or overall issues...',
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              if (_jobDescriptionController.text.trim().isNotEmpty) {
                setState(() => _currentStep++);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe the job')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, 
              foregroundColor: Colors.white, 
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Next: Summary & Finish', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(LucideIcons.chevronRight, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- STEP 4: ESTIMATE ---

  Widget _buildEstimateStep() {
    double subtotal = 0;
    for(var item in _estimateItems) {
      subtotal += item.total;
    }
    double tax = subtotal * 0.18;
    double total = subtotal + tax;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Row(
            children: [
              Icon(LucideIcons.clipboardCheck, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Customer', _selectedCustomer?.name ?? 'Unknown'),
                        _buildSummaryRow('Vehicle', _selectedVehicle?.number ?? 'Unknown'),
                        const Divider(height: 32),
                        ..._estimateItems.where((it) => it.descriptionController.text.isNotEmpty).map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item.descriptionController.text, style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                              Text('₹${item.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                        const Divider(height: 32),
                        _buildSummaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _buildSummaryRow('GST (18%)', '₹${tax.toStringAsFixed(2)}'),
                        const Divider(height: 32),
                        _buildSummaryRow('Total Amount', '₹${total.toStringAsFixed(2)}', isBold: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _finishAndShare(total),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        icon: const Icon(LucideIcons.messageSquare, size: 18),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _printPdf(total, subtotal, tax),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: AppColors.foreground, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        icon: const Icon(LucideIcons.download, size: 18),
                        label: const Text('PDF'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                     onPressed: () async {
                       await _saveJobAndEstimate(total);
                       if (context.mounted) {
                         Navigator.pop(context);
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(
                             content: Text('Service record saved successfully!'),
                             backgroundColor: AppColors.success,
                           )
                         );
                       }
                     },
                     child: const Text('Save & Finish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isBold ? AppColors.foreground : AppColors.mutedForeground, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14)),
        Text(value, style: TextStyle(color: isBold ? AppColors.primary : AppColors.foreground, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14)),
      ],
    );
  }

  Future<void> _saveJobAndEstimate(double total) async {
    try {
      setState(() => _isLoading = true);
      // Create Job
      await Supabase.instance.client.from('jobs').insert({
        'vehicle_id': _selectedVehicle!.id,
        'customer_id': _selectedCustomer!.id,
        'description': _jobDescriptionController.text,
        'estimated_amount': total,
        'status': 'booked',
      });
      // Optionally save individual items if there was a job_items table. 
      // For now, job is the main record.
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint(e.toString());
    }
  }

  Future<void> _finishAndShare(double total) async {
    await _saveJobAndEstimate(total);
    
    final phone = '91${_selectedCustomer!.phone.replaceAll(RegExp(r'[^0-9]'), '')}';
    StringBuffer message = StringBuffer();
    message.writeln('*Service Estimate - GetGarage*');
    message.writeln('--------------------------------');
    message.writeln('👤 *Customer:* ${_selectedCustomer!.name}');
    message.writeln('🚗 *Vehicle:* ${_selectedVehicle!.number} (${_selectedVehicle!.model})');
    message.writeln('📝 *Job:* ${_jobDescriptionController.text}');
    message.writeln('--------------------------------');
    message.writeln('*Breakdown:*');
    for(var item in _estimateItems) {
      if(item.descriptionController.text.isNotEmpty) {
         message.writeln('• ${item.descriptionController.text}: ₹${item.total.toStringAsFixed(0)}');
      }
    }
    message.writeln('--------------------------------');
    message.writeln('*Total Amount: ₹${total.toStringAsFixed(2)}*');
    message.writeln('Tax included (GST 18%)');
    message.writeln('\nThank you for choosing GetGarage!');
    
    final encodedMessage = Uri.encodeComponent(message.toString());
    final url = Uri.parse('whatsapp://send?phone=$phone&text=$encodedMessage');
    final webUrl = Uri.parse('https://wa.me/$phone?text=$encodedMessage');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
         await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _printPdf(double total, double subtotal, double tax) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('GetGarage', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text('Your Trusted Auto Care Partner', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('ESTIMATE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                        pw.Text('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('CLIENT DETAILS:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text(_selectedCustomer!.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Phone: ${_selectedCustomer!.phone}'),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('VEHICLE DETAILS:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text(_selectedVehicle!.number, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Model: ${_selectedVehicle!.model}'),
                          pw.Text('Color: ${_selectedVehicle!.color}'),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Text('JOB DESCRIPTION:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                pw.SizedBox(height: 4),
                pw.Text(_jobDescriptionController.text, style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 30),
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  cellHeight: 30,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.center,
                    3: pw.Alignment.centerRight,
                    4: pw.Alignment.centerRight,
                  },
                  data: <List<String>>[
                    <String>['Description', 'Type', 'Qty', 'Unit Price', 'Total'],
                    ..._estimateItems.map((item) => [
                      item.descriptionController.text,
                      item.type.toUpperCase(),
                      item.quantityController.text,
                      '₹${item.unitPriceController.text}',
                      '₹${item.total.toStringAsFixed(2)}'
                    ]),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text('Subtotal: ', style: const pw.TextStyle(fontSize: 12)),
                            pw.SizedBox(width: 20),
                            pw.Text('₹${subtotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          children: [
                            pw.Text('GST (18%): ', style: const pw.TextStyle(fontSize: 12)),
                            pw.SizedBox(width: 20),
                            pw.Text('₹${tax.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.Divider(color: PdfColors.grey400),
                        pw.Row(
                          children: [
                            pw.Text('Total Amount: ', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(width: 20),
                            pw.Text('₹${total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Divider(color: PdfColors.grey400),
                pw.Center(
                  child: pw.Text('Thank you for choosing GetGarage! For any queries, please call us.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Estimate_${_selectedVehicle!.number}.pdf',
    );
  }
}
