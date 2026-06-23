import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/mall_data.dart';

/// Loads venue data from local JSON assets.
///
/// To migrate to a server: replace the body of [loadMallData] with an HTTP GET
/// and parse the same JSON structure — no other code changes needed.
class DataService {
  Future<MallData> loadMallData() async {
    final jsonStr = await rootBundle.loadString('assets/data/mall_data.json');
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return MallData.fromJson(json);
  }
}
