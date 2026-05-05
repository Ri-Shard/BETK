import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bet_opportunity_model.dart';

abstract class ScannerLocalDataSource {
  Future<List<BetOpportunityModel>> getCachedBets();
  Future<void> cacheBets(List<BetOpportunityModel> bets);
}

class ScannerLocalDataSourceImpl implements ScannerLocalDataSource {
  static const String CACHE_KEY = 'cached_bets';

  @override
  Future<List<BetOpportunityModel>> getCachedBets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(CACHE_KEY);
    
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => BetOpportunityModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<void> cacheBets(List<BetOpportunityModel> bets) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = bets.map((bet) => bet.toJson()).toList();
    await prefs.setString(CACHE_KEY, json.encode(jsonList));
  }
}
