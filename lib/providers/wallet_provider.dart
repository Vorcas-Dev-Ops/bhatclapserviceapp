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
  final String? errorMessage;

  WalletState({
    required this.status,
    this.balance = 0.0,
    this.transactions = const [],
    this.reviews = const [],
    this.credits = 144,
    this.errorMessage,
  });

  factory WalletState.initial() => WalletState(status: WalletStatus.initial);

  WalletState copyWith({
    WalletStatus? status,
    double? balance,
    List<dynamic>? transactions,
    List<dynamic>? reviews,
    int? credits,
    String? errorMessage,
  }) {
    return WalletState(
      status: status ?? this.status,
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      reviews: reviews ?? this.reviews,
      credits: credits ?? this.credits,
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
      // 1. Get wallet info
      final walletResponse = await _apiClient.dio.get('/api/wallets/me');
      double balance = 0.0;
      List<dynamic> transactions = [];
      if (walletResponse.statusCode == 200) {
        balance = (walletResponse.data['balance'] as num?)?.toDouble() ?? 0.0;
        transactions = walletResponse.data['transactions'] ?? [];
      }

      // 2. Get reviews list
      final reviewsResponse = await _apiClient.dio.get('/api/reviews/my');
      List<dynamic> reviews = [];
      if (reviewsResponse.statusCode == 200 && reviewsResponse.data is List) {
        reviews = reviewsResponse.data;
      }

      state = state.copyWith(
        status: WalletStatus.loaded,
        balance: balance,
        transactions: transactions,
        reviews: reviews,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _ref.read(authProvider.notifier).logout();
      }
      state = state.copyWith(
        status: WalletStatus.error,
        errorMessage: e.response?.data['message'] ?? 'Failed to load wallet/reviews info',
      );
    }
  }

  // Withdraw wallet balance (REST API)
  Future<bool> withdrawMoney(double amount) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/wallets/withdraw',
        data: {'amount': amount},
      );
      if (response.statusCode == 200) {
        // Reload wallet details
        await fetchWalletAndReviews();
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _ref.read(authProvider.notifier).logout();
      }
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
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _ref.read(authProvider.notifier).logout();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Add credits locally
  void addCredits(int amount) {
    state = state.copyWith(credits: state.credits + amount);
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WalletNotifier(apiClient: apiClient, ref: ref);
});
