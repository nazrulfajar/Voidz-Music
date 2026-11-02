import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/isar_provider.dart';
import '../../features/settings/data/models/app_settings_model.dart';

final dioProvider = Provider<Dio>((ref) {
  final isar = ref.watch(isarProvider);
  String baseUrl = 'http://10.0.2.2:8000'; // fallback
  
  final settings = isar.appSettingsModels.getSync(1);
  if (settings != null && settings.backendBaseUrl.trim().isNotEmpty) {
    baseUrl = settings.backendBaseUrl;
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl, 
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  
  dio.interceptors.add(
    RetryInterceptor(
      dio: dio,
      logPrint: print, 
      retries: 3, 
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 3),
      ],
    ),
  );

  return dio;
});
