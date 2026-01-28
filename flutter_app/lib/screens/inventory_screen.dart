import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../repositories/inventory_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryItem {
  final String id;
  final String name;
  final String category;
  final double stock;
  final double minStock;
  final String unit;
  final double costPrice;
  final double sellingPrice;
  final String vendor;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.minStock,
    required this.unit,
    required this.costPrice,
    required this.sellingPrice,
    required this.vendor,
  });
}

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

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
               StreamBuilder<List<InventoryItem>>(
                stream: InventoryRepository().getInventory(),
                builder: (context, snapshot) {
                   if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                   final inventoryItems = snapshot.data!;
                   final lowStockItems = inventoryItems.where((item) => item.stock < item.minStock).toList();
                   final totalValue = inventoryItems.fold(0.0, (acc, item) => acc + (item.stock * item.costPrice));

                   return Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       _buildStatsGrid(context, inventoryItems.length, lowStockItems.length, totalValue),
                       const SizedBox(height: 24),
                       _buildSearchBox(),
                       const SizedBox(height: 24),
                       _buildInventoryList(inventoryItems),
                     ],
                   );
                }
               ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Add Item'),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final stockController = TextEditingController();
    final minStockController = TextEditingController();
    final costController = TextEditingController();
    final sellingController = TextEditingController();
    final vendorController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Add Inventory Item', style: TextStyle(color: AppColors.foreground)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Item Name', labelStyle: TextStyle(color: AppColors.mutedForeground)),
                    style: const TextStyle(color: AppColors.foreground),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: 'Category', labelStyle: TextStyle(color: AppColors.mutedForeground)),
                    style: const TextStyle(color: AppColors.foreground),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: stockController,
                      decoration: const InputDecoration(labelText: 'Stock', labelStyle: TextStyle(color: AppColors.mutedForeground)),
                      style: const TextStyle(color: AppColors.foreground),
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(
                      controller: minStockController,
                      decoration: const InputDecoration(labelText: 'Min Stock', labelStyle: TextStyle(color: AppColors.mutedForeground)),
                      style: const TextStyle(color: AppColors.foreground),
                      keyboardType: TextInputType.number,
                    )),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: costController,
                      decoration: const InputDecoration(labelText: 'Cost Price', labelStyle: TextStyle(color: AppColors.mutedForeground)),
                      style: const TextStyle(color: AppColors.foreground),
                      keyboardType: TextInputType.number,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(
                      controller: sellingController,
                      decoration: const InputDecoration(labelText: 'Selling Price', labelStyle: TextStyle(color: AppColors.mutedForeground)),
                      style: const TextStyle(color: AppColors.foreground),
                      keyboardType: TextInputType.number,
                    )),
                  ]),
                  const SizedBox(height: 12),
                   TextFormField(
                    controller: vendorController,
                    decoration: const InputDecoration(labelText: 'Vendor', labelStyle: TextStyle(color: AppColors.mutedForeground)),
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
                  await InventoryRepository().addItem({
                    'name': nameController.text,
                    'category': categoryController.text,
                    'stock': int.tryParse(stockController.text) ?? 0,
                    'min_stock': int.tryParse(minStockController.text) ?? 0,
                    'cost_price': double.tryParse(costController.text) ?? 0,
                    'selling_price': double.tryParse(sellingController.text) ?? 0,
                    'vendor': vendorController.text,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item added successfully!')),
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
          'Inventory',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
        const SizedBox(height: 4),
        const Text(
          'Manage spare parts and supplies',
          style: TextStyle(color: AppColors.mutedForeground),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, int totalItems, int lowStock, double totalValue) {
    return GridView.count(
      crossAxisCount: 1,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 4,
      children: [
        _buildStatCard(
          context,
          'Total Items',
          totalItems.toString(),
          LucideIcons.package,
          AppColors.primary,
        ),
        _buildStatCard(
          context,
          'Low Stock Items',
          lowStock.toString(),
          LucideIcons.alertTriangle,
          AppColors.warning,
        ),
        _buildStatCard(
          context,
          'Inventory Value',
          '₹${NumberFormat('#,##,###').format(totalValue)}',
          LucideIcons.trendingDown,
          AppColors.success,
        ),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search parts...',
        prefixIcon: const Icon(LucideIcons.search, size: 20, color: AppColors.mutedForeground),
        fillColor: AppColors.secondary,
      ),
    );
  }

  Widget _buildInventoryList(List<InventoryItem> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = items[index];
        final isLowStock = item.stock < item.minStock;
        final stockPercentage = (item.stock / item.minStock).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLowStock ? AppColors.warning.withOpacity(0.5) : AppColors.border.withOpacity(0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(item.category, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.moreVertical, size: 18),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Stock Level', style: TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                  Text(
                    '${item.stock} ${item.unit}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isLowStock ? AppColors.warning : AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: stockPercentage,
                backgroundColor: AppColors.secondary,
                valueColor: AlwaysStoppedAnimation<Color>(isLowStock ? AppColors.warning : AppColors.success),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Min: ${item.minStock} ${item.unit}', style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                  if (isLowStock)
                    const Row(
                      children: [
                        Icon(LucideIcons.alertTriangle, size: 12, color: AppColors.warning),
                        SizedBox(width: 4),
                        Text('Low Stock', style: TextStyle(fontSize: 11, color: AppColors.warning)),
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
                        const Text('Cost', style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                        Text('₹${item.costPrice.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Selling', style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                        Text('₹${item.sellingPrice.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Vendor: ${item.vendor}', style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
            ],
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
      },
    );
  }
}
