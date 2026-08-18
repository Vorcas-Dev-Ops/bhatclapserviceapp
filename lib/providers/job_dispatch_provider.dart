import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import 'api_providers.dart';
import 'auth_provider.dart';
import 'provider_profile_provider.dart';
import 'jobs_provider.dart';
import 'package:geolocator/geolocator.dart';

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
    final bId = json['booking_id'];
    final bookingIdStr = bId is Map ? (bId['_id'] ?? '').toString() : bId?.toString() ?? '';

    String resolvedServiceName = '';
    
    // 1. Direct service_name field if not default placeholder
    final directName = (json['service_name'] ?? json['subservice_name'] ?? json['title'] ?? json['name'])?.toString().trim() ?? '';
    if (directName.isNotEmpty && directName != 'New Service Request') {
      resolvedServiceName = directName;
    }

    // 2. Inspect nested booking_id object if populated
    if (resolvedServiceName.isEmpty && bId is Map) {
      final bName = (bId['service_name'] ?? bId['variant_name'] ?? bId['subservice_name'] ?? bId['title'] ?? bId['name'])?.toString().trim() ?? '';
      if (bName.isNotEmpty && bName != 'New Service Request') {
        resolvedServiceName = bName;
      }

      if (resolvedServiceName.isEmpty) {
        final items = bId['items'];
        if (items is List && items.isNotEmpty) {
          final first = items.first;
          if (first is Map) {
            final subservice = first['subservice_id'];
            if (subservice is Map) {
              final sName = (subservice['subservice_name'] ?? subservice['name'] ?? subservice['title'])?.toString().trim() ?? '';
              if (sName.isNotEmpty) resolvedServiceName = sName;
            }
            if (resolvedServiceName.isEmpty) {
              final iName = (first['subservice_name'] ?? first['name'] ?? first['title'])?.toString().trim() ?? '';
              if (iName.isNotEmpty) resolvedServiceName = iName;
            }
          }
        }
      }

      if (resolvedServiceName.isEmpty) {
        final subservice = bId['subservice_id'];
        if (subservice is Map) {
          final sName = (subservice['subservice_name'] ?? subservice['name'] ?? subservice['title'])?.toString().trim() ?? '';
          if (sName.isNotEmpty) resolvedServiceName = sName;
        }
      }

      if (resolvedServiceName.isEmpty && bId['category_name'] != null) {
        final cName = bId['category_name'].toString().trim();
        if (cName.isNotEmpty) resolvedServiceName = cName;
      }
    }

    // 3. Inspect direct subservice_id object
    if (resolvedServiceName.isEmpty) {
      final subservice = json['subservice_id'];
      if (subservice is Map) {
        final sName = (subservice['subservice_name'] ?? subservice['name'] ?? subservice['title'])?.toString().trim() ?? '';
        if (sName.isNotEmpty) resolvedServiceName = sName;
      }
    }

    // 4. Inspect direct items array
    if (resolvedServiceName.isEmpty) {
      final items = json['items'];
      if (items is List && items.isNotEmpty) {
        final first = items.first;
        if (first is Map) {
          final iName = (first['subservice_name'] ?? first['name'] ?? first['title'])?.toString().trim() ?? '';
          if (iName.isNotEmpty) resolvedServiceName = iName;
        }
      }
    }

    // 5. Category fallback
    if (resolvedServiceName.isEmpty && json['category_name'] != null) {
      final cName = json['category_name'].toString().trim();
      if (cName.isNotEmpty) resolvedServiceName = cName;
    }

    if (resolvedServiceName.isEmpty) {
      resolvedServiceName = directName.isNotEmpty ? directName : 'Service Request';
    }

    // Amount extraction
    double resolvedAmount = (json['amount'] as num?)?.toDouble() ?? 0.0;
    if (resolvedAmount == 0.0 && json['payable_amount'] != null) {
      resolvedAmount = (json['payable_amount'] as num).toDouble();
    }
    if (resolvedAmount == 0.0 && bId is Map) {
      resolvedAmount = (bId['payable_amount'] ?? bId['total_amount'] ?? 0.0 as num).toDouble();
    }

    // Address extraction
    String resolvedAddress = loc['address']?.toString() ?? '';
    String resolvedCity = loc['city']?.toString() ?? '';
    String resolvedPincode = loc['pincode']?.toString() ?? '';
    if (resolvedAddress.isEmpty && bId is Map) {
      final addrObj = bId['address_id'];
      if (addrObj is Map) {
        resolvedAddress = (addrObj['address_line'] ?? addrObj['address_line_1'] ?? addrObj['area_locality'] ?? '').toString();
        resolvedCity = (addrObj['city'] ?? '').toString();
        resolvedPincode = (addrObj['pincode'] ?? '').toString();
      }
    }

    // Schedule extraction
    String resolvedDate = json['scheduled_at']?.toString() ?? '';
    String resolvedTime = json['booking_time']?.toString() ?? '';
    if (bId is Map) {
      if (resolvedDate.isEmpty) resolvedDate = (bId['selected_date'] ?? bId['scheduled_at'] ?? '').toString();
      if (resolvedTime.isEmpty) resolvedTime = (bId['selected_time_slot'] ?? bId['booking_time'] ?? '').toString();
    }

    return JobRequestModel(
      requestId: json['request_id'] ?? json['_id'] ?? '',
      bookingId: bookingIdStr,
      displayId: json['display_id'] ?? (bId is Map ? bId['booking_id'] : '') ?? '',
      serviceName: resolvedServiceName,
      amount: resolvedAmount,
      address: resolvedAddress,
      city: resolvedCity,
      pincode: resolvedPincode,
      distance: loc['distance']?.toString() ?? '',
      scheduledAt: resolvedDate,
      bookingTime: resolvedTime,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : DateTime.now().add(const Duration(minutes: 5)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': bookingId.isNotEmpty ? bookingId : requestId,
      'request_id': requestId,
      'booking_id': bookingId,
      'display_id': displayId,
      'subservice_id': {'subservice_name': serviceName},
      'payable_amount': amount,
      'booking_time': bookingTime,
      'scheduled_at': scheduledAt,
      'address_id': {
        'address_line': address,
        'city': city,
        'pincode': pincode,
      },
    };
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
        final isOnline = profile['isOnline'] == true || profile['availability_status'] == 'available';
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
    print('=== toggleAvailability started. Current online: ${state.isOnline}, nextStatus: $nextStatus ===');

    if (nextStatus == 'available') {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          state = state.copyWith(error: 'Please enable location services to go online.');
          return false;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            state = state.copyWith(error: 'Location permission is required to go online.');
            return false;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          state = state.copyWith(error: 'Location permissions are permanently denied, please enable in settings.');
          return false;
        }
      } catch (e) {
        print('=== toggleAvailability permission check error: $e ===');
      }
    }

    try {
      final response = await _apiClient.dio.put(
        '/api/providers/availability',
        data: {'status': nextStatus},
      );
      print('=== toggleAvailability response status: ${response.statusCode}, data: ${response.data} ===');
      if (response.statusCode == 200) {
        final isOnline = response.data['isOnline'] == true || response.data['status'] == 'available';
        state = state.copyWith(isOnline: isOnline, error: null);
        if (isOnline) {
          _connectSocketAndStartTracking();
        } else {
          _disconnectSocketAndStopTracking();
        }
        return true;
      }
    } catch (e) {
      print('=== toggleAvailability endpoint error: $e. Attempting fallback via /api/providers/me ===');
    }

    // Fallback: update availability_status via provider profile endpoint if availability endpoint returns 403/error
    try {
      final fallbackRes = await _apiClient.dio.put(
        '/api/providers/me',
        data: {'availability_status': nextStatus},
      );
      if (fallbackRes.statusCode == 200) {
        final isOnline = nextStatus == 'available';
        state = state.copyWith(isOnline: isOnline, error: null);
        if (isOnline) {
          _connectSocketAndStartTracking();
        } else {
          _disconnectSocketAndStopTracking();
        }
        return true;
      }
    } on DioException catch (e) {
      print('=== toggleAvailability fallback DioException: $e ===');
      final msg = e.response?.data['message'] ?? 'Failed to update availability status.';
      state = state.copyWith(error: msg);
      return false;
    } catch (e) {
      print('=== toggleAvailability fallback exception: $e ===');
      state = state.copyWith(error: 'Failed to update availability status.');
      return false;
    }

    state = state.copyWith(error: 'Failed to update availability status.');
    return false;
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
      try {
        final bId = jobRequest.bookingId.isNotEmpty ? jobRequest.bookingId : jobRequest.requestId;
        int notifId = bId.hashCode.abs() % 100000;
        NotificationService.showNotification(
          id: notifId,
          title: 'New Booking Request',
          body: 'You have received a new booking request for ${jobRequest.serviceName} of ₹${jobRequest.amount.toStringAsFixed(0)}.',
          payload: jsonEncode({'booking_id': bId, 'type': 'job_dispatch'}),
        );
      } catch (_) {}
    });

    _socket!.on('new_chat_message', (data) {
      try {
        final senderRole = data['senderRole'] ?? data['sender_role'];
        if (senderRole != 'provider') {
          final senderName = data['senderName'] ?? data['sender_name'] ?? 'Customer';
          final text = data['text'] ?? data['message'] ?? 'Sent you a message';
          final convId = data['conversation_id'] ?? data['conversationId'] ?? '';
          final bookingId = data['booking_id'] ?? data['bookingId'] ?? convId.toString().replaceAll('CHAT-BKG-', '');
          int notifId = (data['_id'] ?? data['id'] ?? DateTime.now().millisecondsSinceEpoch).toString().hashCode.abs() % 100000;
          NotificationService.showNotification(
            id: notifId,
            title: 'New message from $senderName',
            body: text,
            payload: jsonEncode({'booking_id': bookingId, 'type': 'chat'}),
          );
        }
      } catch (_) {}
    });

    _socket!.onDisconnect((_) {
      state = state.copyWith(isConnecting: false);
    });

    // Report location immediately, then start periodic GPS reporting (every 12 seconds)
    _reportLocation();
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

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return; // Location services are disabled.
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return; // Location permissions are denied
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return; // Permissions are denied forever
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Emit live coordinate update to WebSocket
      if (_socket != null && _socket!.connected) {
        _socket!.emit('updateLocation', {
          'providerId': providerId,
          'lat': position.latitude,
          'lng': position.longitude,
        });
      }

      // Backup & OSRM Engine: update live coordinates in database & Redis via REST API Gateway
      try {
        await _apiClient.dio.post(
          '/api/providers/location/update',
          data: {
            'lat': position.latitude,
            'lng': position.longitude,
            'heading': position.heading,
            'speed': position.speed,
            'accuracy': position.accuracy,
          },
        );
      } catch (_) {}

      try {
        await _apiClient.dio.patch(
          '/api/providers/live-location',
          data: {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'heading': position.heading,
            'speed': position.speed,
            'accuracy': position.accuracy,
          },
        );
      } catch (_) {}
    } catch (e) {
      print('=== Location report error: $e ===');
    }
  }

  // Accept incoming job request
  Future<bool> acceptJob(String requestId) async {
    if (requestId.trim().isEmpty) {
      state = state.copyWith(error: 'Invalid request ID');
      return false;
    }
    try {
      final response = await _apiClient.dio.post(
        '/api/providers/job-requests/$requestId/accept',
      );
      if (response.statusCode == 200) {
        state = state.copyWith(clearActiveJob: true, error: null);
        await _ref.read(jobsProvider.notifier).fetchAllJobs();
        return true;
      }
      final msg = response.data is Map ? (response.data['message'] ?? response.data['error'])?.toString() : null;
      state = state.copyWith(error: msg ?? 'Failed to accept job');
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message']?.toString() ?? e.response?.data['error']?.toString())
          : null;
      state = state.copyWith(error: msg ?? 'Failed to accept job');
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to accept job: $e');
      return false;
    }
  }

  // Reject incoming job request
  Future<bool> rejectJob(String requestId) async {
    if (requestId.trim().isEmpty) return false;
    try {
      final response = await _apiClient.dio.post(
        '/api/providers/job-requests/$requestId/reject',
      );
      if (response.statusCode == 200) {
        state = state.copyWith(clearActiveJob: true, error: null);
        await _ref.read(jobsProvider.notifier).fetchAllJobs();
        return true;
      }
      return false;
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message']?.toString() ?? e.response?.data['error']?.toString())
          : null;
      state = state.copyWith(error: msg ?? 'Failed to reject job');
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to reject job: $e');
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
