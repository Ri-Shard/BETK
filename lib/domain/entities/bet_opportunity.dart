class BetOpportunity {
  final String sport;
  final String homeTeam;
  final String awayTeam;
  final String betOn;
  final double odd;
  final String bookie;
  final double ev;
  final int recommendedBet;
  final bool isAllIn;
  final String date;
  final String marketType;
  final String? point;

  BetOpportunity({
    required this.sport,
    required this.homeTeam,
    required this.awayTeam,
    required this.betOn,
    required this.odd,
    required this.bookie,
    required this.ev,
    required this.recommendedBet,
    required this.isAllIn,
    required this.date,
    this.marketType = 'H2H',
    this.point,
  });
}
