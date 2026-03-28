import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  Stream<bool> get connectionStream => _connectionController.stream;

  Future<void> initialize() async {
    // Check initial connectivity (connectivity_plus 6.x returns List<ConnectivityResult>)
    final results = await _connectivity.checkConnectivity();
    _isConnected = _hasConnection(results);
    _connectionController.add(_isConnected);

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((results) {
      final wasConnected = _isConnected;
      _isConnected = _hasConnection(results);
      
      if (wasConnected != _isConnected) {
        debugPrint('Connectivity changed: ${_isConnected ? "Connected" : "Disconnected"}');
        _connectionController.add(_isConnected);
      }
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _connectionController.close();
  }
}
