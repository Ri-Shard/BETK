import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/bet_opportunity.dart';
import '../../domain/repositories/scanner_repository.dart';

class DashboardController extends GetxController {
  final ScannerRepository repository;

  DashboardController({required this.repository});

  final RxList<BetOpportunity> bets = <BetOpportunity>[].obs;
  final RxBool isLoading = false.obs;
  final RxString lastUpdate = "Nunca".obs;

  List<BetOpportunity> get top7Bets {
    // Ordenar de Menor a Mayor Cuota (Los resultados más probables y seguros)
    final sortedBets = List<BetOpportunity>.from(bets)..sort((a, b) => a.odd.compareTo(b.odd));
    return sortedBets.take(7).toList();
  }

  double get parlayOdds {
    final top7 = top7Bets;
    if (top7.isEmpty) return 0.0;
    return top7.fold(1.0, (prev, bet) => prev * bet.odd);
  }

  int get parlayRecommendedBet {
    final top7 = top7Bets;
    if (top7.isEmpty) return 0;
    return top7.map((b) => b.recommendedBet).reduce((a, b) => a < b ? a : b);
  }

  @override
  void onInit() {
    super.onInit();
    _forceClearCache();
  }

  Future<void> _forceClearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_bets');
      bets.clear();
      await runScanner(); // Iniciar escaneo limpio automático
    } catch (e) {
      // Ignore
    }
  }

  Future<void> loadCachedResults() async {
    try {
      final cachedBets = await repository.getCachedBets();
      if (cachedBets.isNotEmpty) {
        bets.assignAll(cachedBets);
        lastUpdate.value = bets.first.date;
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "No se pudo cargar la caché: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> runScanner() async {
    isLoading.value = true;
    bets.clear(); // Limpiar la pantalla inmediatamente
    try {
      final results = await repository.scanMarket();
      bets.assignAll(results);
      if (bets.isNotEmpty) {
        lastUpdate.value = bets.first.date;
      }
    } catch (e) {
      Get.snackbar(
        "Error al escanear",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
