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
      if (orders.isNotEmpty) {
        state = NotificationState(
          count: orders.length,
          pendingOrders: orders,
        );
        debugPrint('Found ${orders.length} pending web orders');
      }
    } catch (e) {
      debugPrint('Error polling orders: $e');
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
