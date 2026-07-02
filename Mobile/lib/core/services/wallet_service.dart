import '../api/api_client.dart';

class WalletTxn {
  final String id;
  final int amount; // negative = debit, positive = credit
  final String type; // topup | payment | refund
  final String? description;
  final DateTime createdAt;

  const WalletTxn({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory WalletTxn.fromJson(Map<String, dynamic> j) => WalletTxn(
        id: j['id'] as String? ?? '',
        amount: (j['amount'] as num?)?.round() ?? 0,
        type: j['type'] as String? ?? 'payment',
        description: j['description'] as String?,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class WalletData {
  final int balance;
  final String currency;
  final List<WalletTxn> transactions;

  const WalletData({
    required this.balance,
    required this.currency,
    required this.transactions,
  });

  factory WalletData.fromJson(Map<String, dynamic> j) => WalletData(
        balance: (j['balance'] as num?)?.round() ?? 0,
        currency: j['currency'] as String? ?? 'KZT',
        transactions: (j['transactions'] as List<dynamic>?)
                ?.map((e) => WalletTxn.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
      );

  static const empty = WalletData(balance: 0, currency: 'KZT', transactions: []);
}

class WalletService {
  final _api = ApiClient.instance;

  /// GET /wallet. Returns null on error so the UI can show a retry/empty state.
  Future<WalletData?> getWallet() async {
    try {
      final res = await _api.dio.get('/wallet');
      return WalletData.fromJson(Map<String, dynamic>.from(res.data as Map));
    } catch (_) {
      return null;
    }
  }
}
