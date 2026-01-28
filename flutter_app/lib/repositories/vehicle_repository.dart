import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../screens/vehicles_screen.dart';

class VehicleRepository {
  final SupabaseClient _client = SupabaseService().client;

  Stream<List<Vehicle>> getVehicles() {
    return _client
        .from('vehicles')
        .stream(primaryKey: ['id'])
        .order('number', ascending: true)
        .map((data) => data.map((json) => Vehicle(
              id: json['id'],
              number: json['number'],
              model: json['model'] ?? '',
              year: json['year'] ?? '',
              owner: '', // Requires join or separate fetch if needed, for flat list using placeholders or simple fetch
              color: json['color'] ?? '',
              fuelType: json['fuel_type'] ?? '',
              lastService: json['last_service'] != null
                  ? DateTime.parse(json['last_service']).toString().split(' ')[0]
                  : 'N/A',
              totalServices: json['total_services'] ?? 0,
              status: json['status'] ?? 'active',
            )).toList());
  }

  Future<void> addVehicle(Map<String, dynamic> data) async {
    await _client.from('vehicles').insert(data);
  }
}
