import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({Key? key}) : super(key: key);

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  String? _selectedPlanId;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final policyProvider = context.read<PolicyProvider>();
    await Future.wait([
      policyProvider.fetchPlans(),
      policyProvider.fetchRecommendedPlan(),
    ]);
  }

  Future<void> _confirmSelection() async {
    if (_selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plan')),
      );
      return;
    }

    setState(() => _isConfirming = true);

    final policyProvider = context.read<PolicyProvider>();
    final success = await policyProvider.selectPlan(_selectedPlanId!);

    if (success) {
      final confirmed = await policyProvider.confirmPolicy();
      if (confirmed) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    }

    if (mounted) {
      setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final policyProvider = context.watch<PolicyProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Choose Your Plan'),
      ),
      body: policyProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select the best coverage for your needs',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 16),
                    ..._buildPlanCards(policyProvider),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isConfirming ? null : _confirmSelection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A7A7A),
                          disabledBackgroundColor: Colors.grey[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isConfirming
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildPlanCards(PolicyProvider policyProvider) {
    final isRecommendedAvailable = policyProvider.recommendedPlan != null;
    final recommendedId = policyProvider.recommendedPlan?.id;

    return policyProvider.plans
        .map(
          (plan) => _PlanCard(
            plan: plan,
            isSelected: _selectedPlanId == plan.id,
            isRecommended: isRecommendedAvailable && plan.id == recommendedId,
            onTap: () {
              setState(() => _selectedPlanId = plan.id);
            },
          ),
        )
        .toList();
  }
}

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF1A7A7A) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? const Color(0xFF1A7A7A).withOpacity(0.05) : Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.tagline,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF1A7A7A) : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF1A7A7A),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Recommended Badge
            if (isRecommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[300]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Recommended for you',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Price
            Text(
              plan.displayPrice,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A7A7A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Paid by you monthly',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 16),

            // Coverage List
            Text(
              'Coverage includes:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            ..._buildCoverageList(plan.coverage),

            const SizedBox(height: 12),

            // Max Payout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Max Coverage',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '₹${plan.maxPayout.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A7A7A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCoverageList(List<String> coverage) {
    return coverage
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 16, color: Color(0xFF1A7A7A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}
