import '../../domain/entities/bet_opportunity.dart';

class BetOpportunityModel extends BetOpportunity {
  BetOpportunityModel({
    required super.sport,
    required super.homeTeam,
    required super.awayTeam,
    required super.betOn,
    required super.odd,
    required super.bookie,
    required super.ev,
    required super.recommendedBet,
    required super.isAllIn,
    required super.date,
    super.marketType,
    super.point,
  });

  factory BetOpportunityModel.fromJson(Map<String, dynamic> json) {
    return BetOpportunityModel(
      sport: json['sport'] ?? '',
      homeTeam: json['home'] ?? '',
      awayTeam: json['away'] ?? '',
      betOn: json['bet_on'] ?? '',
      odd: (json['odd'] as num?)?.toDouble() ?? 0.0,
      bookie: json['bookie'] ?? '',
      ev: (json['ev'] as num?)?.toDouble() ?? 0.0,
      recommendedBet: (json['recommended_bet'] as num?)?.toInt() ?? 0,
      isAllIn: json['all_in'] ?? false,
      date: json['date'] ?? '',
      marketType: json['market_type'] ?? 'H2H',
      point: json['point'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sport': sport,
      'home': homeTeam,
      'away': awayTeam,
      'bet_on': betOn,
      'odd': odd,
      'bookie': bookie,
      'ev': ev,
      'recommended_bet': recommendedBet,
      'all_in': isAllIn,
      'date': date,
      'market_type': marketType,
      'point': point,
    };
  }
}
