import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../screens/customers_screen.dart';

class CustomerRepository {
  final SupabaseClient _client = SupabaseService().client;

  Stream<List<Customer>> getCustomers() {
    return _client
        .from('customers')
        .stream(primaryKey: ['id'])
        .order('name', ascending: true)
        .map((data) => data.map((json) => Customer(
              id: json['id'],
              name: json['name'],
              phone: json['phone'] ?? '',
              email: json['email'] ?? '',
              address: json['address'] ?? '',
              vehicles: [], // To be populated if needed, or handled separately
              totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
              lastVisit: json['last_visit'] != null 
                  ? DateTime.parse(json['last_visit']).toString().split(' ')[0] 
                  : 'N/A',
            )).toList());
  }

  Future<void> addCustomer(Map<String, dynamic> data) async {
    await _client.from('customers').insert(data);
  }
}
