import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class EstimateItem {
  final String id;
  String type; // 'part' or 'labor'
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;

  EstimateItem({
    required this.id,
    required this.type,
    String description = '',
    int quantity = 1,
    double unitPrice = 0,
  })  : descriptionController = TextEditingController(text: description),
        quantityController = TextEditingController(text: quantity.toString()),
        unitPriceController = TextEditingController(text: unitPrice.toString());

  String get description => descriptionController.text;
  int get quantity => int.tryParse(quantityController.text) ?? 0;
  double get unitPrice => double.tryParse(unitPriceController.text) ?? 0;

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
  }
}

class EstimatesScreen extends StatefulWidget {
  const EstimatesScreen({super.key});

  @override
  State<EstimatesScreen> createState() => _EstimatesScreenState();
}

class _EstimatesScreenState extends State<EstimatesScreen> {
  final _customerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _modelController = TextEditingController();

  final List<EstimateItem> _items = [];

  @override
  void initState() {
    super.initState();
    _addNewItem(type: 'labor');
  }

  void _addNewItem({String type = 'part'}) {
    final newItem = EstimateItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
    );
    newItem.quantityController.addListener(_onItemChanged);
    newItem.unitPriceController.addListener(_onItemChanged);
    _items.add(newItem);
  }

  void _onItemChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _phoneController.dispose();
    _vehicleNumberController.dispose();
    _modelController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  double get subtotal => _items.fold(0.0, (sum, item) => sum + (item.quantity * item.unitPrice));
  double get taxAmount => subtotal * 0.18;
  double get total => subtotal + taxAmount;

  void _addItem() {
    setState(() {
      _addNewItem();
    });
  }

  void _removeItem(String id) {
    if (_items.length > 1) {
      setState(() {
        final itemIndex = _items.indexWhere((it) => it.id == id);
        if (itemIndex != -1) {
          _items[itemIndex].dispose();
          _items.removeAt(itemIndex);
        }
      });
    }
  }

  Future<void> _shareViaWhatsApp() async {
    final customerName = _customerNameController.text.trim();
    String phone = _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final vehicleNumber = _vehicleNumberController.text.trim();
    final model = _modelController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number'), backgroundColor: AppColors.destructive),
      );
      return;
    }

    // Ensure country code (defaulting to 91 for India if 10 digits)
    if (phone.length == 10) {
      phone = '91$phone';
    }

    // Format Message
    StringBuffer message = StringBuffer();
    message.writeln('*Estimate from GetGarage*');
    message.writeln('---------------------------');
    if (customerName.isNotEmpty) message.writeln('Customer: $customerName');
    if (vehicleNumber.isNotEmpty) message.writeln('Vehicle: $vehicleNumber ($model)');
    message.writeln();
    message.writeln('*Service Details:*');
    
    for (var item in _items) {
      if (item.description.isNotEmpty) {
        message.writeln('- ${item.description}: ${item.quantity} x ₹${item.unitPrice.toInt()} = ₹${(item.quantity * item.unitPrice).toInt()}');
      }
    }
    
    message.writeln();
    message.writeln('Subtotal: ₹${NumberFormat('#,##,###').format(subtotal)}');
    message.writeln('GST (18%): ₹${NumberFormat('#,##,###').format(taxAmount)}');
    message.writeln('*Total: ₹${NumberFormat('#,##,###').format(total)}*');
    message.writeln('---------------------------');
    message.writeln('Thank you for choosing GetGarage!');

    final encodedMessage = Uri.encodeComponent(message.toString());
    
    // Attempt multiple schemes for better compatibility
    final whatsappUrl = Uri.parse('whatsapp://send?phone=$phone&text=$encodedMessage');
    final webUrl = Uri.parse('https://wa.me/$phone?text=$encodedMessage');

    try {
      // On some Android 11+ devices, canLaunchUrl returns false even if app is there.
      // We try the app-specific scheme first.
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: try direct launch of web URL if queries are still failing
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.destructive),
          );
       }
    }
  }

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
              _buildSectionTitle(context, LucideIcons.user, 'Customer & Vehicle Details'),
              const SizedBox(height: 12),
              _buildDetailsForm(),
              const SizedBox(height: 32),
              _buildSectionTitle(context, LucideIcons.fileText, 'Estimate Items'),
              const SizedBox(height: 8),
              const Text('Add parts and labor charges', style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
              const SizedBox(height: 16),
              _buildItemsList(),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _addItem,
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Add Item'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppColors.border, style: BorderStyle.solid),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              _buildSummaryCard(context),
              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ElevatedButton.icon(
          onPressed: _shareViaWhatsApp,
          icon: const Icon(LucideIcons.send, size: 18),
          label: const Text('Share via WhatsApp'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          'Create Estimate',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
        const SizedBox(height: 4),
        const Text(
          'Generate service estimate for customers',
          style: TextStyle(color: AppColors.mutedForeground),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDetailsForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          _buildTextField('Customer Name', 'Enter customer name', controller: _customerNameController),
          const SizedBox(height: 16),
          _buildTextField('Phone Number', '+91 XXXXXXXXXX', icon: LucideIcons.phone, controller: _phoneController),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField('Vehicle Number', 'MH 01 AB 1234', icon: LucideIcons.car, controller: _vehicleNumberController)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField('Vehicle Model', 'e.g. Swift', controller: _modelController)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {IconData? icon, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.mutedForeground)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 16, color: AppColors.mutedForeground) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    return Column(
      children: _items.map((item) => _buildItemRow(item)).toList(),
    );
  }

  Widget _buildItemRow(EstimateItem item) {
    return Container(
      key: ValueKey(item.id),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Type', style: TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: item.type,
                      dropdownColor: AppColors.card,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      style: const TextStyle(fontSize: 13, color: AppColors.foreground),
                      items: const [
                        DropdownMenuItem(value: 'part', child: Text('Part')),
                        DropdownMenuItem(value: 'labor', child: Text('Labor')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            item.type = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: _buildSmallField('Description', 'e.g. Oil change', controller: item.descriptionController),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _removeItem(item.id),
                icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.destructive),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSmallField('Qty', '1', controller: item.quantityController, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildSmallField('Unit Price (₹)', '0', controller: item.unitPriceController, keyboardType: TextInputType.number)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  Widget _buildSmallField(String label, String hint, {TextEditingController? controller, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13, color: AppColors.foreground),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withOpacity(0.1), Colors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.calculator, color: AppColors.primary, size: 20),
              SizedBox(width: 10),
              Text('Estimate Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          _buildSummaryRow('Subtotal', '₹${NumberFormat('#,##,###').format(subtotal)}'),
          const SizedBox(height: 12),
          _buildSummaryRow('GST (18%)', '₹${NumberFormat('#,##,###').format(taxAmount)}'),
          const Divider(height: 32, color: AppColors.border),
          _buildSummaryRow('Total', '₹${NumberFormat('#,##,###').format(total)}', isBold: true),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isBold ? 18 : 14, color: isBold ? AppColors.foreground : AppColors.mutedForeground, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: isBold ? 18 : 14, color: isBold ? AppColors.primary : AppColors.foreground, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
