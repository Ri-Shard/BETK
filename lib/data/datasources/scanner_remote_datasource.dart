import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/bet_opportunity_model.dart';

abstract class ScannerRemoteDataSource {
  Future<List<BetOpportunityModel>> fetchOpportunities();
}

class ScannerRemoteDataSourceImpl implements ScannerRemoteDataSource {
  final String _apiKey = "995f155b57a456dec029427821150f19";
  final String _baseUrl = "https://v3.football.api-sports.io";
  final double _bankrollCop = 10000.0;

  Map<String, dynamic> _calculateBetSize(double bankroll, double decimalOdds, double winProbability) {
    double b = decimalOdds - 1.0;
    double p = winProbability;
    double q = 1.0 - p;
    if (p <= 0 || b <= 0) return {'amount': 0, 'isAllIn': false};
    double kellyFraction = (p * b - q) / b;
    if (kellyFraction <= 0) return {'amount': 0, 'isAllIn': false};
    double safeFraction = kellyFraction * 0.5;
    double betAmount = bankroll * safeFraction;
    bool isAllIn = false;
    if (kellyFraction >= 0.30) {
      isAllIn = true;
      betAmount = bankroll;
    }
    if (betAmount > bankroll) betAmount = bankroll;
    return {'amount': betAmount.toInt(), 'isAllIn': isAllIn};
  }

  Map<String, double> _removeMarginPowerMethod(Map<String, double> odds) {
    if (odds.isEmpty) return {};
    
    double sumProbs(double k) {
      double sum = 0;
      for (double odd in odds.values) {
        sum += math.pow((1.0 / odd), (1.0 / k));
      }
      return sum;
    }

    double overround = 0;
    for (double odd in odds.values) overround += 1.0/odd;
    
    if (overround <= 1.0) {
      Map<String, double> trueProbs = {};
      for (var entry in odds.entries) {
         trueProbs[entry.key] = (1.0 / entry.value) / overround;
      }
      return trueProbs;
    }

    double kLow = 1.0;
    double kHigh = 2.0;
    double kMid = 1.0;

    for (int i = 0; i < 20; i++) {
      kMid = (kLow + kHigh) / 2.0;
      double sum = sumProbs(kMid);
      if (sum > 1.0) {
        kLow = kMid;
      } else {
        kHigh = kMid;
      }
    }

    Map<String, double> trueProbs = {};
    for (var entry in odds.entries) {
      trueProbs[entry.key] = math.pow((1.0 / entry.value), (1.0 / kMid)).toDouble();
    }
    return trueProbs;
  }

  Future<Map<int, Map<String, String>>> _fetchFixtures(String date) async {
    final uri = Uri.parse("$_baseUrl/fixtures?date=$date");
    final response = await http.get(uri, headers: {"x-apisports-key": _apiKey});
    if (response.statusCode != 200) throw Exception("Error fetching fixtures");
    
    final data = json.decode(response.body);
    final responseList = data['response'] as List<dynamic>? ?? [];
    
    Map<int, Map<String, String>> fixturesMap = {};
    for (var item in responseList) {
      final fixtureId = item['fixture']['id'] as int;
      final homeTeam = item['teams']['home']['name'] as String;
      final awayTeam = item['teams']['away']['name'] as String;
      final leagueName = item['league']['name'] as String;
      
      fixturesMap[fixtureId] = {
        'home': homeTeam,
        'away': awayTeam,
        'league': leagueName,
      };
    }
    return fixturesMap;
  }

  @override
  Future<List<BetOpportunityModel>> fetchOpportunities() async {
    List<BetOpportunityModel> resultsData = [];
    final date = DateTime.now().toIso8601String().split('T')[0];

    try {
      final fixturesMap = await _fetchFixtures(date);
      
      for (int page = 1; page <= 3; page++) {
        final uri = Uri.parse("$_baseUrl/odds?date=$date&page=$page");
        final response = await http.get(uri, headers: {"x-apisports-key": _apiKey});
        
        if (response.statusCode != 200) continue;
        
        final data = json.decode(response.body);
        final responseList = data['response'] as List<dynamic>? ?? [];
        if (responseList.isEmpty) break; // Si no hay más datos, terminar
        
        for (var event in responseList) {
          final fixtureId = event['fixture']['id'] as int;
          final teams = fixturesMap[fixtureId];
          if (teams == null) continue;
          
          final String homeTeam = teams['home']!;
          final String awayTeam = teams['away']!;
          final String sport = teams['league']!;
          
          final bookmakers = event['bookmakers'] as List<dynamic>? ?? [];
          
          Map<String, Map<String?, Map<String, Map<String, double>>>> marketData = {};
          
          for (var bookmaker in bookmakers) {
            final String bookieName = bookmaker['name']; 
            
            final bets = bookmaker['bets'] as List<dynamic>? ?? [];
            for (var bet in bets) {
              final String marketName = bet['name']; 
              final values = bet['values'] as List<dynamic>? ?? [];
              
              for (var val in values) {
                final rawValue = val['value'].toString();
                final double price = double.tryParse(val['odd'].toString()) ?? 0.0;
                if (price == 0.0) continue;
                
                String betOn = rawValue;
                String? pointStr;
                
                if (rawValue.contains(RegExp(r'\d+\.\d+')) || rawValue.contains(RegExp(r'\d+'))) {
                   final match = RegExp(r'(.*?)\s+([-+]?\d*\.?\d+)').firstMatch(rawValue);
                   if (match != null) {
                     betOn = match.group(1)!.trim();
                     pointStr = match.group(2)!.trim();
                   }
                }
                
                marketData.putIfAbsent(marketName, () => {});
                marketData[marketName]!.putIfAbsent(pointStr, () => {});
                marketData[marketName]![pointStr]!.putIfAbsent(bookieName, () => {});
                marketData[marketName]![pointStr]![bookieName]![betOn] = price;
              }
            }
          }
          
          BetOpportunityModel? bestBetForEvent;
          
          for (var marketName in marketData.keys) {
            for (var pointStr in marketData[marketName]!.keys) {
              final bookiesMap = marketData[marketName]![pointStr]!;
              
              Map<String, double>? sharpOdds;
              if (bookiesMap.containsKey('Pinnacle')) {
                sharpOdds = bookiesMap['Pinnacle'];
              } else if (bookiesMap.containsKey('Betfair')) {
                sharpOdds = bookiesMap['Betfair'];
              }
              
              if (sharpOdds == null) continue; 
              
              Map<String, double> trueProbs = _removeMarginPowerMethod(sharpOdds);
              if (trueProbs.isEmpty) continue;
              
              for (var bookieName in bookiesMap.keys) {
                final oddsMap = bookiesMap[bookieName]!;
                
                for (var entry in oddsMap.entries) {
                  final String name = entry.key;
                  final double odd = entry.value;
                  
                  final double? trueProb = trueProbs[name];
                  if (trueProb == null) continue;
                  
                  double ev = (trueProb * odd) - 1;
                  
                  if (ev > 0.02 && ev < 0.20 && trueProb >= 0.35 && odd <= 3.0) {
                    if (bestBetForEvent == null || ev > (bestBetForEvent.ev / 100)) {
                      final nowStr = DateTime.now().toString(); 
                      final now = nowStr.split('.')[0]; 
                      final betInfo = _calculateBetSize(_bankrollCop, odd, trueProb);
                      
                      bestBetForEvent = BetOpportunityModel(
                        sport: sport,
                        homeTeam: homeTeam,
                        awayTeam: awayTeam,
                        betOn: name,
                        odd: odd,
                        bookie: bookieName,
                        ev: double.parse((ev * 100).toStringAsFixed(2)),
                        recommendedBet: betInfo['amount'],
                        isAllIn: betInfo['isAllIn'],
                        date: now,
                        marketType: marketName,
                        point: pointStr,
                      );
                    }
                  }
                }
              }
            }
          }

          if (bestBetForEvent != null) {
            resultsData.add(bestBetForEvent);
          }
        }
        
        final paging = data['paging'];
        if (paging != null && paging['current'] == paging['total']) {
          break;
        }
      }
    } catch (e) {
      throw Exception("Error de conexión API-Football: $e");
    }
    
    return resultsData;
  }
}
