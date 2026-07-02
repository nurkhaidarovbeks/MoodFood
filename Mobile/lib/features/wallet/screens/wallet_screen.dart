import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Wallet — balance + transaction history + top-up entry point.
///
/// DESIGN PHASE: uses placeholder data shaped exactly like the backend
/// `GET /wallet` response ({ balance, currency, transactions: [...] }) so
/// wiring a WalletService/WalletProvider later is a drop-in swap.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  // Placeholder — mirrors GET /wallet response shape.
  static const _balance = 12500;
  static const _currency = '₸';
  static const _transactions = <_Txn>[
    _Txn(
      title: 'Premium subscription',
      subtitle: 'Monthly plan',
      amount: -4990,
      type: 'payment',
      date: 'Today, 14:32',
      icon: Icons.workspace_premium_outlined,
    ),
    _Txn(
      title: 'Wallet top-up',
      subtitle: 'PayPal',
      amount: 10000,
      type: 'topup',
      date: 'Yesterday, 09:10',
      icon: Icons.add_card_outlined,
    ),
    _Txn(
      title: 'Recipe pack',
      subtitle: 'High-protein bundle',
      amount: -1500,
      type: 'payment',
      date: 'Jun 28, 18:45',
      icon: Icons.restaurant_menu_outlined,
    ),
    _Txn(
      title: 'Wallet top-up',
      subtitle: 'Card •••• 4242',
      amount: 10000,
      type: 'topup',
      date: 'Jun 25, 11:02',
      icon: Icons.add_card_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  _BalanceCard(balance: _balance, currency: _currency),
                  const SizedBox(height: 20),
                  const _QuickActions(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_transactions.isEmpty)
                    const _EmptyTransactions()
                  else
                    ..._transactions.map((t) => _TransactionRow(txn: t)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6),
                ],
              ),
              child: const Icon(Icons.arrow_back,
                  size: 20, color: AppTheme.textDark),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Wallet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Balance card ────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final int balance;
  final String currency;
  const _BalanceCard({required this.balance, required this.currency});

  String get _formatted {
    final s = balance.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.primaryDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Balance',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white.withValues(alpha: 0.9), size: 22),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatted,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                currency,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18, color: AppTheme.primaryDark),
                  SizedBox(width: 6),
                  Text(
                    'Top Up',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick actions ───────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
            child: _ActionTile(
                icon: Icons.add_card_outlined, label: 'Top Up')),
        SizedBox(width: 12),
        Expanded(
            child: _ActionTile(
                icon: Icons.receipt_long_outlined, label: 'History')),
        SizedBox(width: 12),
        Expanded(
            child: _ActionTile(
                icon: Icons.workspace_premium_outlined, label: 'Premium')),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ActionTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryDark),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Transaction row ─────────────────────────────────────────────────────────

class _TransactionRow extends StatelessWidget {
  final _Txn txn;
  const _TransactionRow({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isCredit = txn.amount > 0;
    final amountColor =
        isCredit ? AppTheme.primaryDark : const Color(0xFFE53935);
    final sign = isCredit ? '+' : '−';
    final absAmount = txn.amount.abs().toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCredit
                  ? AppTheme.primary.withValues(alpha: 0.1)
                  : const Color(0xFFFDECEA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              txn.icon,
              size: 20,
              color: isCredit ? AppTheme.primaryDark : const Color(0xFFE53935),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${txn.subtitle} · ${txn.date}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$sign$absAmount ₸',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: const [
          Text('💳', style: TextStyle(fontSize: 44)),
          SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Top up your wallet to get started',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Model (mirrors backend transaction) ─────────────────────────────────────

class _Txn {
  final String title;
  final String subtitle;
  final int amount; // negative = debit, positive = credit
  final String type; // topup | payment | refund
  final String date;
  final IconData icon;

  const _Txn({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
    required this.date,
    required this.icon,
  });
}
