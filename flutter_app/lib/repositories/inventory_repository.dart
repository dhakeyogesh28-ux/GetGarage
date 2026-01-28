import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../screens/inventory_screen.dart';

class InventoryRepository {
  final SupabaseClient _client = SupabaseService().client;

  Stream<List<InventoryItem>> getInventory() {
    return _client
        .from('inventory')
        .stream(primaryKey: ['id'])
        .order('name', ascending: true)
        .map((data) => data.map((json) => InventoryItem(
              id: json['id'],
              name: json['name'],
              category: json['category'] ?? '',
              stock: (json['stock'] as num?)?.toDouble() ?? 0.0,
              minStock: (json['min_stock'] as num?)?.toDouble() ?? 0.0,
              unit: json['unit'] ?? 'pcs',
              costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
              sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
              vendor: json['vendor'] ?? '',
            )).toList());
  }

  Future<void> addItem(Map<String, dynamic> data) async {
    await _client.from('inventory').insert(data);
  }
}
