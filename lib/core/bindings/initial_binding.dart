import 'package:get/get.dart';
import '../../data/datasources/scanner_local_datasource.dart';
import '../../data/datasources/scanner_remote_datasource.dart';
import '../../data/repositories/scanner_repository_impl.dart';
import '../../domain/repositories/scanner_repository.dart';
import '../../presentation/controllers/dashboard_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Data Sources
    Get.lazyPut<ScannerRemoteDataSource>(() => ScannerRemoteDataSourceImpl());
    Get.lazyPut<ScannerLocalDataSource>(() => ScannerLocalDataSourceImpl());

    // Repository
    Get.lazyPut<ScannerRepository>(() => ScannerRepositoryImpl(
      remoteDataSource: Get.find(),
      localDataSource: Get.find(),
    ));

    // Controller
    Get.lazyPut(() => DashboardController(repository: Get.find()));
  }
}
