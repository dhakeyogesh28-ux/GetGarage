import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class Transaction {
  final String id;
  final String type; // 'income' or 'expense'
  final String category;
  final String description;
  final double amount;
  final String date;
  final String paymentMode;

  Transaction({
    required this.id,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    required this.paymentMode,
  });
}

class KhatabookScreen extends StatelessWidget {
  const KhatabookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = [
      Transaction(
        id: "1",
        type: "income",
        category: "Service",
        description: "Full service - Honda City (MH 12 AB 1234)",
        amount: 8500,
        date: "08 Jan 2025",
        paymentMode: "UPI",
      ),
      Transaction(
        id: "2",
        type: "expense",
        category: "Parts Purchase",
        description: "Brake pads and oil filters from Bosch",
        amount: 12500,
        date: "07 Jan 2025",
        paymentMode: "Bank Transfer",
      ),
      Transaction(
        id: "3",
        type: "income",
        category: "Repair",
        description: "Clutch replacement - Hyundai Creta",
        amount: 15000,
        date: "07 Jan 2025",
        paymentMode: "Cash",
      ),
      Transaction(
        id: "4",
        type: "expense",
        category: "Utilities",
        description: "Electricity bill - December",
        amount: 4500,
        date: "05 Jan 2025",
        paymentMode: "UPI",
      ),
      Transaction(
        id: "5",
        type: "income",
        category: "Service",
        description: "AC servicing - Maruti Swift",
        amount: 3500,
        date: "05 Jan 2025",
        paymentMode: "UPI",
      ),
      Transaction(
        id: "6",
        type: "expense",
        category: "Salary",
        description: "Staff salary - December",
        amount: 45000,
        date: "01 Jan 2025",
        paymentMode: "Bank Transfer",
      ),
      Transaction(
        id: "7",
        type: "income",
        category: "Service",
        description: "Wheel alignment - Tata Nexon",
        amount: 2500,
        date: "30 Dec 2024",
        paymentMode: "Cash",
      ),
    ];

    double totalIncome = transactions.where((t) => t.type == 'income').fold(0.0, (acc, t) => acc + t.amount);
    double totalExpense = transactions.where((t) => t.type == 'expense').fold(0.0, (acc, t) => acc + t.amount);
    double netBalance = totalIncome - totalExpense;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildSummaryGrid(context, totalIncome, totalExpense, netBalance),
              const SizedBox(height: 24),
              _buildFilters(),
              const SizedBox(height: 24),
              _buildTransactionsList(transactions),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khatabook',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                const SizedBox(height: 4),
                const Text(
                  'Track all income and expenses',
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showTransactionDialog(context, 'income'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(LucideIcons.plusCircle, size: 18),
                label: const Text('Add Income', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showTransactionDialog(context, 'expense'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.destructive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(LucideIcons.minusCircle, size: 18),
                label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
      ],
    );
  }

  void _showTransactionDialog(BuildContext context, String type) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isIncome = type == 'income';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isIncome ? LucideIcons.trendingUp : LucideIcons.trendingDown, 
              color: isIncome ? AppColors.success : AppColors.destructive
            ),
            const SizedBox(width: 12),
            Text(
              'Add ${isIncome ? 'Income' : 'Expense'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  hintText: '0.00',
                  prefixIcon: const Icon(LucideIcons.indianRupee, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  hintText: isIncome ? 'e.g. Service, Repair' : 'e.g. Parts, Rent, Salary',
                  prefixIcon: const Icon(LucideIcons.tag, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter details...',
                  prefixIcon: const Icon(LucideIcons.fileText, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedForeground)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                // In a real app, you'd save this to Supabase here
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${isIncome ? 'Income' : 'Expense'} recorded successfully!'),
                    backgroundColor: isIncome ? AppColors.success : AppColors.destructive,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isIncome ? AppColors.success : AppColors.destructive,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save Record'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context, double income, double expense, double balance) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSummaryCard(context, 'Total Income', income, LucideIcons.trendingUp, AppColors.success)),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryCard(context, 'Total Expenses', expense, LucideIcons.trendingDown, AppColors.destructive)),
          ],
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(context, 'Net Balance', balance, LucideIcons.indianRupee, balance >= 0 ? AppColors.primary : AppColors.destructive, isFull: true),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildSummaryCard(BuildContext context, String title, double value, IconData icon, Color color, {bool isFull = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.15), color.withOpacity(0.02)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${NumberFormat('#,##,###').format(value.abs())}',
            style: TextStyle(
              fontSize: isFull ? 28 : 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', isSelected: true),
          const SizedBox(width: 8),
          _buildFilterChip('Income', color: AppColors.success),
          const SizedBox(width: 8),
          _buildFilterChip('Expenses', color: AppColors.destructive),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {bool isSelected = false, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? (color ?? AppColors.primary) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSelected ? Colors.transparent : AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : (color ?? AppColors.foreground),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<Transaction> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final t = items[index];
        final isIncome = t.type == 'income';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isIncome ? AppColors.success : AppColors.destructive).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                  color: isIncome ? AppColors.success : AppColors.destructive,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      '${t.category} • ${t.date} • ${t.paymentMode}',
                      style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'}₹${NumberFormat('#,##,###').format(t.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isIncome ? AppColors.success : AppColors.destructive,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: -0.05, end: 0);
      },
    );
  }
}
