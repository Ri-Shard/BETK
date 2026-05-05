import '../entities/bet_opportunity.dart';

abstract class ScannerRepository {
  Future<List<BetOpportunity>> scanMarket();
  Future<List<BetOpportunity>> getCachedBets();
}
