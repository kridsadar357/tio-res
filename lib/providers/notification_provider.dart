import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});

class NotificationState {
  final int count;
  final List<WebOrder> pendingOrders;

  NotificationState({this.count = 0, this.pendingOrders = const []});

  NotificationState copyWith({int? count, List<WebOrder>? pendingOrders}) {
    return NotificationState(
      count: count ?? this.count,
      pendingOrders: pendingOrders ?? this.pendingOrders,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(NotificationState()) {
    _startPolling();
  }

  Timer? _timer;
  final ApiService _apiService = ApiService();
  int _consecutiveErrors = 0;

  void _startPolling() {
    // Initial check
    _checkOrders();
    // Poll every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkOrders();
    });
  }

  Future<void> _checkOrders() async {
    // Only poll if API is enabled
    if (!_apiService.isEnabled) {
      return;
    }

    try {
      final orders = await _apiService.fetchPendingOrders();
      
      // Reset error counter on success
      if (_consecutiveErrors > 0) {
        _consecutiveErrors = 0;
      }
      
      // Always update state with current orders
      state = NotificationState(
        count: orders.length,
        pendingOrders: orders,
      );
      if (orders.isNotEmpty) {
        debugPrint('Found ${orders.length} pending web orders');
      }
    } catch (e) {
      _consecutiveErrors++;
      // Only log errors occasionally to reduce log spam (every 5th error)
      if (_consecutiveErrors == 1 || _consecutiveErrors % 5 == 0) {
        debugPrint('Error polling orders (attempt $_consecutiveErrors): $e');
      }
    }
  }

  /// Manually trigger a check
  Future<void> refresh() async {
    await _checkOrders();
  }

  /// Acknowledge an order (mark as received)
  Future<void> acknowledgeOrder(int orderId) async {
    await _apiService.acknowledgeOrder(orderId);
    // Remove from pending list
    state = state.copyWith(
      pendingOrders: state.pendingOrders.where((o) => o.id != orderId).toList(),
      count: state.count > 0 ? state.count - 1 : 0,
    );
  }

  /// Demo method to trigger notification manually
  void triggerMockNotification() {
    state = state.copyWith(count: state.count + 1);
  }

  void clear() {
    state = NotificationState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
