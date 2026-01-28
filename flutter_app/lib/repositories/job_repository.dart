import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../widgets/job_card.dart'; // For JobStatus enum if defined there, or map string

class JobRepository {
  final SupabaseClient _client = SupabaseService().client;

  Stream<List<Map<String, dynamic>>> getJobs() {
    return _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          if (data.isEmpty) return [];
          
          // Fetch details for these jobs
          // Note: This is an extra query per change, but allows us to get joined data
          final ids = data.map((e) => e['id']).toList();
          final response = await _client
              .from('jobs')
              .select('*, vehicles(*), customers(*)')
              .filter('id', 'in', ids) // Filter by the IDs we just got from stream
              .order('created_at', ascending: false);
              
          return List<Map<String, dynamic>>.from(response);
        });
  }

  // Helper to fetch details with joins (manual join since stream simple mapping is limited)
  // For now, we will fetch raw jobs and might need to fetch related vehicle/customer info separately
  // or use a view. Given simple requirements, we'll try to use what we have or do a view if needed.
  // Actually, Supabase stream emits the row. We need vehicle/customer data for the card.
  // We can't easily join in a stream builder without a view or client-side value join.
  // For "Make it functional", let's create a View in Supabase or fetch related data in the UI.
  // Let's rely on creating a View for easier streaming if possible, but user just ran schema.
  // Alternative: Fetch foreign keys and load details? No, slow list.
  // Best bet: Create a View `jobs_view`? 
  // User said "I had run the new schema". I shouldn't ask for more SQL if avoidable.
  // I will use `select` with modifiers for Stream? 
  // Supabase Flutter SDK constraints: `.stream()` is limited to single table events usually.
  // However, I can use `.from('jobs').stream()` and iterate.
  // But I need customer name etc.
  // Okay, I'll assume for now I can fetch related data or just show IDs/simple data?
  // No, the UI shows Customer Name.
  // I will create a `getJobsWithDetails` future or use a View.
  // Since user just ran schema, maybe I can slip in a View creation if I really need it, or handle it in Dart.
  // Let's try to do it in Dart: For each job, fetch vehicle/customer? That's N+1.
  // Okay, standard way: Create a View. I'll ask user to run one more small script or just handle it gracefully.
  // Actually, `from` in Supabase can resolve joins in `select` but `stream` is strictly change feed of that table.
  // I will just fetch the stream of IDs and then `select(*, vehicles(*, customers(*)))`?
  // No, `stream` returns the data of the table.
  // I will make `getJobs` return a Future for the list for now if Realtime is too complex with Joins without a View.
  // Wait, the task says "Integration", "Real-time".
  // I will use `stream()` on `jobs` and inside the map, I might have to accept I only have local data or I need a View.
  // Let's stick to: Create a View `jobs_with_details` in specific SQL if I can.
  // OR: Just use FutureBuilder with `select('*, vehicles(*, customers(*))')` and poling or refresh button?
  // User asked for "dynamic and real-time".
  // I will IMPLEMENT a View in Dart by fetching related data? No.
  // I'll add `setup_db.sql` updates for a View and ask user?
  // Or: Just stream `jobs` and inside the UI, use `FutureBuilder` for each card to resolve names? Not efficient but works for "Make it functional".
  
  Future<void> addJob(Map<String, dynamic> data) async {
    await _client.from('jobs').insert(data);
  }
}
