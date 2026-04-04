import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/monitoring_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late MonitoringService _monitoringService;

  @override
  void initState() {
    super.initState();
    _monitoringService = MonitoringService();
    _monitoringService.initialize();
    _loadData();
  }

  @override
  void dispose() {
    _monitoringService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final policyProvider = context.read<PolicyProvider>();
    final claimsProvider = context.read<ClaimsProvider>();
    await policyProvider.fetchActivePolicy();
    await claimsProvider.fetchClaimsHistory();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final policyProvider = context.watch<PolicyProvider>();
    final claimsProvider = context.watch<ClaimsProvider>();
    final monitoringProvider = context.watch<MonitoringProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          'Welcome, ${authProvider.user?.fullName.split(' ').first ?? 'User'}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // TODO: Navigate to profile
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Monitoring Status Banner
                if (monitoringProvider.isActive)
                  _MonitoringStatusBanner(
                    status: monitoringProvider.status,
                    lastUpdate: monitoringProvider.lastUpdate,
                    alertMessage: monitoringProvider.alertMessage,
                  ),

                const SizedBox(height: 16),

                // Active Policy Card
                if (policyProvider.hasActivePolicy)
                  _PolicyCard(policy: policyProvider.policy!)
                else
                  _NoPolicyCard(),

                const SizedBox(height: 20),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _QuickActionsGrid(),

                const SizedBox(height: 20),

                // Recent Claims
                if (claimsProvider.claims.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Claims',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to claims history
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._buildClaimsList(claimsProvider.claims.take(3).toList()),
                ] else
                  _EmptyClaimsCard(),

                const SizedBox(height: 20),

                // Tip Banner
                _TipBanner(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildClaimsList(List<Claim> claims) {
    return claims
        .map((claim) => _ClaimCard(claim: claim))
        .toList();
  }
}

class _MonitoringStatusBanner extends StatelessWidget {
  final MonitoringStatus status;
  final DateTime? lastUpdate;
  final String? alertMessage;

  const _MonitoringStatusBanner({
    required this.status,
    this.lastUpdate,
    this.alertMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isAlert = status == MonitoringStatus.alert;
    final backgroundColor = isAlert ? const Color(0xFFFFEBEE) : const Color(0xFFE0F2F1);
    final textColor = isAlert ? Colors.red[700] : const Color(0xFF1A7A7A);
    final icon = isAlert ? Icons.warning_amber : Icons.check_circle;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlert ? Colors.red[200]! : const Color(0xFF1A7A7A),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAlert ? 'Alert Detected' : 'Monitoring Active',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (alertMessage != null)
                  Text(
                    alertMessage!,
                    style: TextStyle(color: textColor, fontSize: 11),
                  ),
              ],
            ),
          ),
          if (lastUpdate != null)
            Text(
              DateFormat('HH:mm').format(lastUpdate!),
              style: TextStyle(color: textColor, fontSize: 10),
            ),
        ],
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final Policy policy;

  const _PolicyCard({required this.policy});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A7A7A), Color(0xFF0D4C4C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    policy.plan.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    policy.id.substring(0, 8).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  policy.statusBadge,
                  style: const TextStyle(
                    color: Color(0xFF1A7A7A),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PolicyInfoItem(
                label: 'Premium',
                value: policy.plan.displayPrice,
              ),
              _PolicyInfoItem(
                label: 'Renewal in',
                value: '${policy.daysUntilRenewal} days',
              ),
              _PolicyInfoItem(
                label: 'Claims Used',
                value: '${policy.claimsUsed}/${policy.claimsLimit}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: policy.claimsUsed / policy.claimsLimit,
              minHeight: 4,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                policy.claimsUsed >= policy.claimsLimit ? Colors.red : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyInfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _PolicyInfoItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _NoPolicyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.shield_outlined, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text(
            'No Active Policy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a plan to get started',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/plans');
            },
            child: const Text('Browse Plans'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      ('File Claim', Icons.description_outlined, '/claims'),
      ('Upgrade Plan', Icons.trending_up, '/plans'),
      ('My Policy', Icons.article_outlined, '/policy'),
      ('Support', Icons.help_outline, '/support'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: actions
          .map(
            (action) => _QuickActionButton(
              label: action.$1,
              icon: action.$2,
              onTap: () => Navigator.pushNamed(context, action.$3),
            ),
          )
          .toList(),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: const Color(0xFF1A7A7A)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  final Claim claim;

  const _ClaimCard({required this.claim});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  claim.typeDisplay,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  claim.statusDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(claim.status),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (claim.payoutAmount != null)
                Text(
                  '₹${claim.payoutAmount!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A7A7A),
                  ),
                ),
              Text(
                DateFormat('dd MMM').format(claim.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _EmptyClaimsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_outlined, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No claims yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        border: Border.all(color: Colors.amber[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Tip',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep location monitoring active to file claims faster during disruptions.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
