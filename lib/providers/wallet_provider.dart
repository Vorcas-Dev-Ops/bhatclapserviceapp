import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import 'api_providers.dart';
import 'provider_profile_provider.dart';
import 'auth_provider.dart';

enum WalletStatus { initial, loading, loaded, error }

class WalletState {
  final WalletStatus status;
  final double balance;
  final List<dynamic> transactions;
  final List<dynamic> reviews;
  final int credits;
  final int leadBalance;
  final String? errorMessage;

  WalletState({
    required this.status,
    this.balance = 0.0,
    this.transactions = const [],
    this.reviews = const [],
    this.credits = 100,
    this.leadBalance = 24,
    this.errorMessage,
  });

  factory WalletState.initial() => WalletState(status: WalletStatus.initial);

  WalletState copyWith({
    WalletStatus? status,
    double? balance,
    List<dynamic>? transactions,
    List<dynamic>? reviews,
    int? credits,
    int? leadBalance,
    String? errorMessage,
  }) {
    return WalletState(
      status: status ?? this.status,
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      reviews: reviews ?? this.reviews,
      credits: credits ?? this.credits,
      leadBalance: leadBalance ?? this.leadBalance,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final ApiClient _apiClient;
  final Ref _ref;

  WalletNotifier({required ApiClient apiClient, required Ref ref})
      : _apiClient = apiClient,
        _ref = ref,
        super(WalletState.initial());

  // Fetch Wallet and Review status together
  Future<void> fetchWalletAndReviews() async {
    state = state.copyWith(status: WalletStatus.loading);
    try {
      // 1. Get wallet info from active balance endpoint
      final walletResponse = await _apiClient.dio.get('/api/providers/wallet/balance');
      double balance = 0.0;
      if (walletResponse.statusCode == 200 && walletResponse.data is Map) {
        final data = walletResponse.data;
        balance = (data['availableBalance'] as num?)?.toDouble() ??
            (data['walletBalance'] as num?)?.toDouble() ??
            (data['balance'] as num?)?.toDouble() ??
            0.0;
      }

      // 1b. Get true ledger transactions
      final txResponse = await _apiClient.dio.get('/api/providers/wallet/transactions');
      List<dynamic> transactions = [];
      if (txResponse.statusCode == 200 && txResponse.data is List) {
        transactions = txResponse.data;
      }

      // 2. Get reviews list
      final reviewsResponse = await _apiClient.dio.get('/api/reviews/my');
      List<dynamic> reviews = [];
      if (reviewsResponse.statusCode == 200 && reviewsResponse.data is List) {
        reviews = reviewsResponse.data;
      }

      // 3. Get lead balance
      int leadBalance = 24;
      try {
        final leadResponse = await _apiClient.dio.get('/api/providers/lead-balance');
        if (leadResponse.statusCode == 200 && leadResponse.data is Map) {
          leadBalance = (leadResponse.data['leadBalance'] as num?)?.toInt() ?? 24;
        }
      } catch (_) {}

      state = state.copyWith(
        status: WalletStatus.loaded,
        balance: balance,
        transactions: transactions,
        reviews: reviews,
        leadBalance: leadBalance,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        status: WalletStatus.error,
        errorMessage: e.response?.data['message'] ?? 'Failed to load wallet/reviews info',
      );
    }
  }

  // Withdraw wallet balance (REST API)
  Future<bool> withdrawMoney(double amount) async {
    final profile = _ref.read(providerProfileProvider).profileData;
    final providerId = profile?['_id'];
    try {
      final response = await _apiClient.dio.post(
        '/api/payouts',
        data: {
          if (providerId != null) 'provider_id': providerId,
          'amount': amount,
          'payment_method': 'bank_transfer',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Reload wallet details
        await fetchWalletAndReviews();
        return true;
      }
      return false;
    } on DioException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  // Request a formal Payout (Provider Service Payouts collection)
  Future<bool> requestPayout(double amount) async {
    final profile = _ref.read(providerProfileProvider).profileData;
    if (profile == null) return false;

    final providerId = profile['_id'];
    try {
      final response = await _apiClient.dio.post(
        '/api/payouts',
        data: {
          'provider_id': providerId,
          'amount': amount,
          'payment_method': 'bank_transfer',
        },
      );
      return response.statusCode == 201;
    } on DioException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  // Add credits locally
  void addCredits(int amount) {
    state = state.copyWith(credits: state.credits + amount);
  }

  // Create Razorpay recharge order
  Future<Map<String, dynamic>?> createRechargeOrder(double amount) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/providers/wallet/recharge/create-order',
        data: {'amount': amount},
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        return e.response?.data as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Verify payment and recharge credits
  Future<bool> verifyRecharge({
    required String orderId,
    required String paymentId,
    required String signature,
    required double amount,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/providers/wallet/recharge/verify',
        data: {
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
          'amount': amount,
        },
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        // Refresh wallet and reviews
        await fetchWalletAndReviews();
        // Refresh provider profile to update balance, etc.
        await _ref.read(providerProfileProvider.notifier).fetchProfile();
        return true;
      }
      return false;
    } on DioException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WalletNotifier(apiClient: apiClient, ref: ref);
});

