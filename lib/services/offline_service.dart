import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus { online, offline }

class OfflineService {
  OfflineService._internal();
  static final OfflineService instance = OfflineService._internal();

  final _connectivity = Connectivity();
  final _statusController = StreamController<NetworkStatus>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  NetworkStatus _currentStatus = NetworkStatus.online;

  NetworkStatus get currentStatus => _currentStatus;
  bool get isOnline => _currentStatus == NetworkStatus.online;
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  Future<void> init() async {
    final initial = await _connectivity.checkConnectivity();
    _updateStatus(initial);

    _subscription ??= _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final online = results.any((result) => result != ConnectivityResult.none);
    final nextStatus = online ? NetworkStatus.online : NetworkStatus.offline;

    if (nextStatus == _currentStatus) {
      return;
    }

    _currentStatus = nextStatus;
    _statusController.add(nextStatus);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _statusController.close();
  }
}
