import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import 'api_providers.dart';
import 'auth_provider.dart';
import 'provider_profile_provider.dart';

class JobRequestModel {
  final String requestId;
  final String bookingId;
  final String displayId;
  final String serviceName;
  final double amount;
  final String address;
  final String city;
  final String pincode;
  final String distance;
  final String scheduledAt;
  final String bookingTime;
  final DateTime expiresAt;

  JobRequestModel({
    required this.requestId,
    required this.bookingId,
    required this.displayId,
    required this.serviceName,
    required this.amount,
    required this.address,
    required this.city,
    required this.pincode,
    required this.distance,
    required this.scheduledAt,
    required this.bookingTime,
    required this.expiresAt,
  });

  factory JobRequestModel.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] ?? {};
    return JobRequestModel(
      requestId: json['request_id'] ?? '',
      bookingId: json['booking_id'] ?? '',
      displayId: json['display_id'] ?? '',
      serviceName: json['service_name'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      address: loc['address'] ?? '',
      city: loc['city'] ?? '',
      pincode: loc['pincode'] ?? '',
      distance: loc['distance'] ?? '',
      scheduledAt: json['scheduled_at'] ?? '',
      bookingTime: json['booking_time'] ?? '',
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : DateTime.now().add(const Duration(minutes: 5)),
    );
  }
}

class DispatchState {
  final bool isOnline;
  final JobRequestModel? activeJob;
  final bool isConnecting;
  final String? error;

  DispatchState({
    this.isOnline = false,
    this.activeJob,
    this.isConnecting = false,
    this.error,
  });

  DispatchState copyWith({
    bool? isOnline,
    JobRequestModel? activeJob,
    bool? isConnecting,
    String? error,
    bool clearActiveJob = false,
  }) {
    return DispatchState(
      isOnline: isOnline ?? this.isOnline,
      activeJob: clearActiveJob ? null : (activeJob ?? this.activeJob),
      isConnecting: isConnecting ?? this.isConnecting,
      error: error ?? this.error,
    );
  }
}

class JobDispatchNotifier extends StateNotifier<DispatchState> {
  final ApiClient _apiClient;
  final Ref _ref;
  io.Socket? _socket;
  Timer? _locationTimer;

  // Delhi mock coordinates for testing
  double _mockLat = 28.6139;
  double _mockLng = 77.2090;

  JobDispatchNotifier({
    required ApiClient apiClient,
    required Ref ref,
  })  : _apiClient = apiClient,
        _ref = ref,
        super(DispatchState()) {
    // Listen to provider profile updates to synchronize online state
    _ref.listen(providerProfileProvider, (previous, next) {
      if (next.status == ProfileStatus.loaded && next.profileData != null) {
        final profile = next.profileData!;
        final isOnline = profile['isOnline'] == true;
        if (isOnline != state.isOnline) {
          state = state.copyWith(isOnline: isOnline);
          if (isOnline) {
            _connectSocketAndStartTracking();
          } else {
            _disconnectSocketAndStopTracking();
          }
        }
      }
    });
  }

  // Toggle availability status online / offline
  Future<bool> toggleAvailability() async {
    final nextStatus = state.isOnline ? 'offline' : 'available';
    try {
      final response = await _apiClient.dio.put(
        '/api/providers/availability',
        data: {'status': nextStatus},
      );
      if (response.statusCode == 200) {
        final isOnline = response.data['isOnline'] == true;
        state = state.copyWith(isOnline: isOnline);
        if (isOnline) {
          _connectSocketAndStartTracking();
        } else {
          _disconnectSocketAndStopTracking();
        }
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update availability status');
      return false;
    }
  }

  void _connectSocketAndStartTracking() {
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    _disconnectSocketAndStopTracking(); // safety clear

    state = state.copyWith(isConnecting: true);

    // Initialize Socket.io Client
    _socket = io.io(
      ApiClient.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      state = state.copyWith(isConnecting: false);
      // Join Room
      _socket!.emit('join', {
        'userId': user.id,
        'role': 'provider',
      });
      print('=== Socket Connected and Joined Room ===');
    });

    // Listen to dispatch updates
    _socket!.on('booking_assigned', (data) {
      print('=== Booking Assigned Received: $data ===');
      final jobRequest = JobRequestModel.fromJson(data);
      state = state.copyWith(activeJob: jobRequest);
    });

    _socket!.onDisconnect((_) {
      state = state.copyWith(isConnecting: false);
    });

    // Start periodic GPS reporting (every 12 seconds)
    _locationTimer = Timer.periodic(const Duration(seconds: 12), (timer) {
      _reportLocation();
    });
  }

  void _disconnectSocketAndStopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _socket?.disconnect();
    _socket = null;
    state = state.copyWith(isConnecting: false);
  }

  // Periodic location reporting
  Future<void> _reportLocation() async {
    final profile = _ref.read(providerProfileProvider).profileData;
    if (profile == null) return;

    final providerId = profile['_id'];
    
    // Simulate slight movements around Delhi for GPS active updates
    _mockLat += 0.0001;
    _mockLng += 0.0001;

    // Emit live coordinate update to WebSocket
    if (_socket != null && _socket!.connected) {
      _socket!.emit('updateLocation', {
        'providerId': providerId,
        'lat': _mockLat,
        'lng': _mockLng,
      });
    }

    // Backup: update live coordinates in database via REST API Gateway
    try {
      await _apiClient.dio.patch(
        '/api/providers/live-location',
        data: {
          'coordinates': [_mockLng, _mockLat],
        },
      );
    } catch (_) {}
  }

  // Accept incoming job request
  Future<bool> acceptJob(String requestId) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/providers/job-requests/$requestId/accept',
      );
      if (response.statusCode == 200) {
        state = state.copyWith(clearActiveJob: true);
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(error: e.response?.data['message'] ?? 'Failed to accept job');
      return false;
    }
  }

  // Reject incoming job request
  Future<bool> rejectJob(String requestId) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/providers/job-requests/$requestId/reject',
      );
      if (response.statusCode == 200) {
        state = state.copyWith(clearActiveJob: true);
        return true;
      }
      return false;
    } on DioException catch (e) {
      state = state.copyWith(error: e.response?.data['message'] ?? 'Failed to reject job');
      return false;
    }
  }

  void clearActiveJob() {
    state = state.copyWith(clearActiveJob: true);
  }

  @override
  void dispose() {
    _disconnectSocketAndStopTracking();
    super.dispose();
  }
}

final jobDispatchProvider =
    StateNotifierProvider<JobDispatchNotifier, DispatchState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return JobDispatchNotifier(apiClient: apiClient, ref: ref);
});
