import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import 'api_providers.dart';
import 'auth_provider.dart';

enum ReferralStatus { initial, loading, loaded, error }

class ReferralState {
  final ReferralStatus status;
  final String referralCode;
  final String referralLink;
  final double totalRewardsEarned;
  final int successfulReferralsCount;
  final int pendingReferralsCount;
  final int myRank;
  final List<Map<String, dynamic>> history;
  final String? errorMessage;
  final bool isApplying;
  final String? applyMessage;

  ReferralState({
    required this.status,
    this.referralCode = '',
    this.referralLink = '',
    this.totalRewardsEarned = 0.0,
    this.successfulReferralsCount = 0,
    this.pendingReferralsCount = 0,
    this.myRank = 0,
    this.history = const [],
    this.errorMessage,
    this.isApplying = false,
    this.applyMessage,
  });

  factory ReferralState.initial() => ReferralState(status: ReferralStatus.initial);

  ReferralState copyWith({
    ReferralStatus? status,
    String? referralCode,
    String? referralLink,
    double? totalRewardsEarned,
    int? successfulReferralsCount,
    int? pendingReferralsCount,
    int? myRank,
    List<Map<String, dynamic>>? history,
    String? errorMessage,
    bool? isApplying,
    String? applyMessage,
  }) {
    return ReferralState(
      status: status ?? this.status,
      referralCode: referralCode ?? this.referralCode,
      referralLink: referralLink ?? this.referralLink,
      totalRewardsEarned: totalRewardsEarned ?? this.totalRewardsEarned,
      successfulReferralsCount: successfulReferralsCount ?? this.successfulReferralsCount,
      pendingReferralsCount: pendingReferralsCount ?? this.pendingReferralsCount,
      myRank: myRank ?? this.myRank,
      history: history ?? this.history,
      errorMessage: errorMessage ?? this.errorMessage,
      isApplying: isApplying ?? this.isApplying,
      applyMessage: applyMessage ?? this.applyMessage,
    );
  }
}

class ReferralNotifier extends StateNotifier<ReferralState> {
  final ApiClient _apiClient;
  final Ref _ref;

  ReferralNotifier({required ApiClient apiClient, required Ref ref})
      : _apiClient = apiClient,
        _ref = ref,
        super(ReferralState.initial());

  Future<void> fetchReferralDashboard() async {
    state = state.copyWith(status: ReferralStatus.loading, errorMessage: null);
    try {
      final response = await _apiClient.dio.get('/api/providers/referral/dashboard');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final stats = data['stats'] as Map<String, dynamic>? ?? {};
        final rawHistory = data['history'] as List<dynamic>? ?? [];

        final historyList = rawHistory.map((item) => Map<String, dynamic>.from(item as Map)).toList();

        state = ReferralState(
          status: ReferralStatus.loaded,
          referralCode: data['referralCode'] ?? '',
          referralLink: data['referralLink'] ?? '',
          totalRewardsEarned: (stats['totalRewardsEarned'] as num?)?.toDouble() ?? 0.0,
          successfulReferralsCount: (stats['successfulReferralsCount'] as num?)?.toInt() ?? 0,
          pendingReferralsCount: (stats['pendingReferralsCount'] as num?)?.toInt() ?? 0,
          myRank: (stats['myRank'] as num?)?.toInt() ?? 0,
          history: historyList,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _ref.read(authProvider.notifier).logout();
      }
      state = state.copyWith(
        status: ReferralStatus.error,
        errorMessage: e.response?.data['message'] ?? 'Failed to load referral dashboard',
      );
    } catch (e) {
      state = state.copyWith(
        status: ReferralStatus.error,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  Future<bool> applyReferralCode(String code) async {
    if (code.trim().isEmpty) return false;
    state = state.copyWith(isApplying: true, applyMessage: null);
    try {
      final response = await _apiClient.dio.post(
        '/api/providers/referral/apply',
        data: {'referralCode': code.trim()},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        state = state.copyWith(
          isApplying: false,
          applyMessage: response.data['message'] ?? 'Referral code applied successfully!',
        );
        // Refresh dashboard after applying
        await fetchReferralDashboard();
        return true;
      } else {
        state = state.copyWith(
          isApplying: false,
          applyMessage: response.data['message'] ?? 'Failed to apply referral code',
        );
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _ref.read(authProvider.notifier).logout();
      }
      final msg = e.response?.data['message'] ?? 'Invalid referral code';
      state = state.copyWith(
        isApplying: false,
        applyMessage: msg,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isApplying: false,
        applyMessage: 'Error applying code',
      );
      return false;
    }
  }
}

final referralProvider =
    StateNotifierProvider<ReferralNotifier, ReferralState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReferralNotifier(apiClient: apiClient, ref: ref);
});
