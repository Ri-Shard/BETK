import '../../domain/entities/bet_opportunity.dart';
import '../../domain/repositories/scanner_repository.dart';
import '../datasources/scanner_local_datasource.dart';
import '../datasources/scanner_remote_datasource.dart';

class ScannerRepositoryImpl implements ScannerRepository {
  final ScannerRemoteDataSource remoteDataSource;
  final ScannerLocalDataSource localDataSource;

  ScannerRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<BetOpportunity>> scanMarket() async {
    final remoteBets = await remoteDataSource.fetchOpportunities();
    await localDataSource.cacheBets(remoteBets);
    return remoteBets;
  }

  @override
  Future<List<BetOpportunity>> getCachedBets() async {
    return await localDataSource.getCachedBets();
  }
}
