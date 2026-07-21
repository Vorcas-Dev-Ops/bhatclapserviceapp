import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import 'api_providers.dart';
import 'job_dispatch_provider.dart';

enum JobsStatus { initial, loading, loaded, error }

class JobsState {
  final JobsStatus status;
  final List<JobRequestModel> newJobs;
  final List<dynamic> bookings;
  final String? errorMessage;

  JobsState({
    required this.status,
    this.newJobs = const [],
    this.bookings = const [],
    this.errorMessage,
  });

  factory JobsState.initial() => JobsState(status: JobsStatus.initial);

  JobsState copyWith({
    JobsStatus? status,
    List<JobRequestModel>? newJobs,
    List<dynamic>? bookings,
    String? errorMessage,
  }) {
    return JobsState(
      status: status ?? this.status,
      newJobs: newJobs ?? this.newJobs,
      bookings: bookings ?? this.bookings,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class JobsNotifier extends StateNotifier<JobsState> {
  final ApiClient _apiClient;

  JobsNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(JobsState.initial());

  // Fetch both pending job requests and accepted/started bookings
  Future<void> fetchAllJobs() async {
    state = state.copyWith(status: JobsStatus.loading);
    try {
      print('Fetching jobs...');
      // 1. Fetch pending job requests (New)
      final reqResponse = await _apiClient.dio.get('/api/providers/job-requests');
      print('reqResponse.statusCode: ${reqResponse.statusCode}');
      print('reqResponse.data: ${reqResponse.data}');
      List<JobRequestModel> newJobsList = [];
      if (reqResponse.statusCode == 200 && reqResponse.data is List) {
        newJobsList = (reqResponse.data as List)
            .map((item) {
              print('Parsing item: $item');
              return JobRequestModel.fromJson(item);
            })
            .toList();
      } else {
        print('reqResponse.data is NOT a List. It is: ${reqResponse.data.runtimeType}');
      }
      print('newJobsList: $newJobsList');

      // 2. Fetch my bookings (Upcoming, Ongoing, Completed)
      final bookingsResponse = await _apiClient.dio.get('/api/bookings/my');
      List<dynamic> bookingsList = [];
      if (bookingsResponse.statusCode == 200) {
        final body = bookingsResponse.data;
        if (body != null && body['data'] is List) {
          bookingsList = body['data'];
        }
      }

      state = state.copyWith(
        status: JobsStatus.loaded,
        newJobs: newJobsList,
        bookings: bookingsList,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        status: JobsStatus.error,
        errorMessage: e.response?.data['message'] ?? 'Failed to retrieve jobs list',
      );
    } catch (e, stack) {
      print('Error parsing jobs: $e\n$stack');
      state = state.copyWith(
        status: JobsStatus.error,
        errorMessage: 'Failed to parse jobs list: $e',
      );
    }
  }

  // Accept a job request
  Future<bool> acceptJob(String requestId) async {
    try {
      final response = await _apiClient.dio.post('/api/providers/job-requests/$requestId/accept');
      if (response.statusCode == 200) {
        await fetchAllJobs();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Reject a job request
  Future<bool> rejectJob(String requestId) async {
    try {
      final response = await _apiClient.dio.post('/api/providers/job-requests/$requestId/reject');
      if (response.statusCode == 200) {
        await fetchAllJobs();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Start service (generates Start OTP)
  Future<bool> startService(String bookingId, List<String> beforePhotos) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/bookings/$bookingId/start-service',
        data: {'beforePhotos': beforePhotos},
      );
      if (response.statusCode == 200) {
        await fetchAllJobs();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Verify Start OTP
  Future<bool> verifyStartOtp(String bookingId, String otp) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/bookings/$bookingId/verify-start-otp',
        data: {'otp': otp},
      );
      if (response.statusCode == 200) {
        await fetchAllJobs();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Finish service (generates End OTP)
  Future<bool> finishService(String bookingId, List<String> afterPhotos) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/bookings/$bookingId/finish-service',
        data: {'afterPhotos': afterPhotos},
      );
      if (response.statusCode == 200) {
        await fetchAllJobs();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Verify End OTP (Completes booking)
  Future<bool> verifyEndOtp(String bookingId, String otp) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/bookings/$bookingId/verify-end-otp',
        data: {'otp': otp},
      );
      if (response.statusCode == 200) {
        await fetchAllJobs();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Resend OTP
  Future<bool> resendOtp(String bookingId, String type) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/bookings/$bookingId/resend-otp',
        data: {'type': type},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

final jobsProvider = StateNotifierProvider<JobsNotifier, JobsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return JobsNotifier(apiClient: apiClient);
});
