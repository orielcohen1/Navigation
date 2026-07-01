import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/mall_data.dart';

/// Loads venue data from Supabase (Postgres + auto-generated REST API).
///
/// Queries the normalized tables (see supabase/schema.sql) and reshapes the
/// rows back into the same nested JSON structure [MallData.fromJson] already
/// parses, so the models and every screen built on top of them are untouched.
///
/// Falls back to the bundled demo JSON when no Supabase project is
/// configured yet, so the app is runnable standalone before that setup step.
class DataService {
  Future<MallData> loadMallData(String venueId) async {
    if (!SupabaseConfig.isConfigured) {
      final jsonStr = await rootBundle.loadString('assets/data/mall_data.json');
      return MallData.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    }

    final client = Supabase.instance.client;
    final venue = await client
        .from('venues')
        .select()
        .eq('id', venueId)
        .single();

    final floors = await client.from('floors').select().eq('venue_id', venueId);
    final nodes = await client.from('nodes').select().eq('venue_id', venueId);
    final edges = await client.from('edges').select().eq('venue_id', venueId);
    final qrCodes = await client.from('qr_codes').select().eq('venue_id', venueId);
    final interFloorEdges =
        await client.from('inter_floor_edges').select().eq('venue_id', venueId);
    final pois = await client.from('pois').select().eq('venue_id', venueId);

    final json = {
      'id': venue['id'],
      'name': venue['name'],
      'mapWidth': venue['map_width'],
      'mapHeight': venue['map_height'],
      'metersPerUnit': venue['meters_per_unit'],
      'floors': floors.map((f) {
        final floorId = f['id'];
        return {
          'id': floorId,
          'name': f['name'],
          'nodes': nodes
              .where((n) => n['floor_id'] == floorId)
              .map((n) => {
                    'id': n['id'],
                    'x': n['x'],
                    'y': n['y'],
                    'label': n['label'],
                  })
              .toList(),
          'edges': edges
              .where((e) => e['floor_id'] == floorId)
              .map((e) => {
                    'from': e['from_node'],
                    'to': e['to_node'],
                    'weight': e['weight'],
                  })
              .toList(),
          'qrCodes': qrCodes
              .where((q) => q['floor_id'] == floorId)
              .map((q) => {
                    'id': q['id'],
                    'nodeId': q['node_id'],
                    'label': q['label'],
                  })
              .toList(),
        };
      }).toList(),
      'interFloorEdges': interFloorEdges
          .map((e) => {
                'fromNodeId': e['from_node'],
                'toNodeId': e['to_node'],
                'type': e['type'],
              })
          .toList(),
      'pois': pois
          .map((p) => {
                'id': p['id'],
                'name': p['name'],
                'category': p['category'],
                'floorId': p['floor_id'],
                'nodeId': p['node_id'],
                'icon': p['icon'],
              })
          .toList(),
    };

    return MallData.fromJson(json);
  }
}
