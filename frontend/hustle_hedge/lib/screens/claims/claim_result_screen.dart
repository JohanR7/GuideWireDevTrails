import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';

class ClaimResultScreen extends StatelessWidget {
  final Claim claim;
  final bool approved;

  const ClaimResultScreen({
    Key? key,
    required this.claim,
    required this.approved,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Result Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: approved ? Colors.green[50] : Colors.red[50],
                ),
                child: Center(
                  child: Icon(
                    approved ? Icons.check_circle : Icons.cancel,
                    size: 48,
                    color: approved ? Colors.green : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Status Title
              Text(
                approved ? 'Claim Approved!' : 'Claim Rejected',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              // Status Description
              Text(
                approved
                    ? 'Your claim has been automatically validated and approved'
                    : 'Your claim could not be validated',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              // Claim Details
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(label: 'Claim ID', value: claim.id.substring(0, 12)),
                    Divider(color: Colors.grey[300]),
                    _DetailRow(label: 'Type', value: claim.typeDisplay),
                    Divider(color: Colors.grey[300]),
                    _DetailRow(
                      label: 'Status',
                      value: claim.statusDisplay,
                    ),
                    Divider(color: Colors.grey[300]),
                    _DetailRow(
                      label: 'Date Filed',
                      value: DateFormat('dd MMM yyyy').format(claim.createdAt),
                    ),
                    if (approved) ...[
                      Divider(color: Colors.grey[300]),
                      _DetailRow(
                        label: 'Payout Amount',
                        value: '₹${claim.payoutAmount?.toStringAsFixed(0) ?? '0'}',
                      ),
                    ] else ...[
                      Divider(color: Colors.grey[300]),
                      _DetailRow(
                        label: 'Reason',
                        value: claim.rejectionReason ?? 'Validation failed',
                      ),
                    ],
                    Divider(color: Colors.grey[300]),
                    _DetailRow(
                      label: 'Trust Score',
                      value: '${(claim.trustScore * 100).toStringAsFixed(0)}%',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A7A7A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/policy'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1A7A7A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View Policy'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
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
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
