import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class PolicyScreen extends StatefulWidget {
  const PolicyScreen({Key? key}) : super(key: key);

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  bool _isUpgrading = false;

  @override
  void initState() {
    super.initState();
    _loadPolicy();
  }

  Future<void> _loadPolicy() async {
    final policyProvider = context.read<PolicyProvider>();
    await policyProvider.fetchActivePolicy();
  }

  Future<void> _handleUpgrade(String planId) async {
    setState(() => _isUpgrading = true);
    
    final policyProvider = context.read<PolicyProvider>();
    final success = await policyProvider.upgradePlan(planId);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan upgraded successfully')),
      );
    }
    
    if (mounted) {
      setState(() => _isUpgrading = false);
    }
  }

  Future<void> _handleCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Policy'),
        content: const Text('Are you sure you want to cancel your policy?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final policyProvider = context.read<PolicyProvider>();
      final success = await policyProvider.cancelPolicy();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Policy cancelled')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final policyProvider = context.watch<PolicyProvider>();

    if (policyProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!policyProvider.hasActivePolicy) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('No Active Policy'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/plans'),
                child: const Text('Browse Plans'),
              ),
            ],
          ),
        ),
      );
    }

    final policy = policyProvider.policy!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('My Policy'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Policy Header Card
              Container(
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
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              policy.plan.tagline,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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
                    Text(
                      policy.plan.displayPrice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Policy Details Grid
              Text(
                'Policy Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Policy Number',
                      value: policy.id.substring(0, 12).toUpperCase(),
                    ),
                    Divider(color: Colors.grey[300]),
                    _DetailRow(
                      label: 'Start Date',
                      value: DateFormat('dd MMM yyyy').format(policy.effectiveDate),
                    ),
                    Divider(color: Colors.grey[300]),
                    _DetailRow(
                      label: 'Renewal Date',
                      value: policy.renewalDate != null
                          ? DateFormat('dd MMM yyyy').format(policy.renewalDate!)
                          : 'N/A',
                    ),
                    Divider(color: Colors.grey[300]),
                    _DetailRow(
                      label: 'Premium Amount',
                      value: '₹${policy.premiumAmount.toStringAsFixed(0)}/month',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Claims Status
              Text(
                'Claims Status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Claims Used'),
                        Text(
                          '${policy.claimsUsed}/${policy.claimsLimit}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: policy.claimsUsed / policy.claimsLimit,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          policy.claimsUsed >= policy.claimsLimit
                              ? Colors.red
                              : const Color(0xFF1A7A7A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (policy.claimsRemaining > 0)
                      Text(
                        '${policy.claimsRemaining.toInt()} claims remaining this period',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Coverage Details
              Text(
                'What\'s Covered',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: policy.plan.coverage
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 20,
                                color: Color(0xFF1A7A7A),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(item),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/claims'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A7A7A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'File a Claim',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isUpgrading ? null : () => _showUpgradePlanDialog(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1A7A7A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Upgrade Plan',
                    style: TextStyle(color: Color(0xFF1A7A7A)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _handleCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel Policy',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpgradePlanDialog() async {
    final policyProvider = context.read<PolicyProvider>();
    
    await policyProvider.fetchPlans();
    
    if (mounted) {
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Upgrade Your Plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: policyProvider.plans.length,
                  itemBuilder: (context, index) {
                    final plan = policyProvider.plans[index];
                    final isCurrentPlan =
                        plan.id == policyProvider.policy!.planId;
                    
                    return ListTile(
                      title: Text(plan.name),
                      subtitle: Text(plan.displayPrice),
                      enabled: !isCurrentPlan,
                      trailing: isCurrentPlan
                          ? const Chip(label: Text('Current'))
                          : null,
                      onTap: isCurrentPlan
                          ? null
                          : () => Navigator.pop(context) as dynamic,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
