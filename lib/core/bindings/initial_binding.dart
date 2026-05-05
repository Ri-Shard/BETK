import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/datasources/scanner_local_datasource.dart';
import '../../data/datasources/scanner_remote_datasource.dart';
import '../../data/repositories/scanner_repository_impl.dart';
import '../../domain/repositories/scanner_repository.dart';
import '../../presentation/controllers/dashboard_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ScannerRemoteDataSource>(() => ScannerRemoteDataSourceImpl());
    Get.lazyPut<ScannerLocalDataSource>(() => ScannerLocalDataSourceImpl());

    Get.lazyPut<ScannerRepository>(() => ScannerRepositoryImpl(
      remoteDataSource: Get.find(),
      localDataSource: Get.find(),
    ));

    Get.lazyPut(() => DashboardController(repository: Get.find()));
  }
}
