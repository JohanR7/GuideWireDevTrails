import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class ClaimsScreen extends StatefulWidget {
  const ClaimsScreen({Key? key}) : super(key: key);

  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen> {
  int _currentStep = 0;
  String? _selectedClaimType;
  String? _description;
  DateTime? _incidentDate;
  TimeOfDay? _incidentTime;

  @override
  Widget build(BuildContext context) {
    final claimsProvider = context.watch<ClaimsProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('File a Claim'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Indicator
              _StepIndicator(
                currentStep: _currentStep,
                totalSteps: 4,
              ),
              const SizedBox(height: 24),

              // Step Content
              if (_currentStep == 0)
                _Step1SelectType(
                  onSelect: (type) => setState(() => _selectedClaimType = type),
                  selectedType: _selectedClaimType,
                )
              else if (_currentStep == 1)
                _Step2Description(
                  onDescriptionChanged: (desc) =>
                      setState(() => _description = desc),
                  description: _description,
                )
              else if (_currentStep == 2)
                _Step3DateTime(
                  onDateSelected: (date) => setState(() => _incidentDate = date),
                  onTimeSelected: (time) => setState(() => _incidentTime = time),
                  selectedDate: _incidentDate,
                  selectedTime: _incidentTime,
                )
              else
                _Step4Confirmation(
                  claimType: _selectedClaimType ?? '',
                  description: _description ?? '',
                  incidentDate: _incidentDate,
                  incidentTime: _incidentTime,
                ),

              const SizedBox(height: 24),

              // Navigation Buttons
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            setState(() => _currentStep = _currentStep - 1),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1A7A7A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_canProceed()) {
                          if (_currentStep < 3) {
                            setState(
                              () => _currentStep = _currentStep + 1,
                            );
                          } else {
                            _submitClaim(claimsProvider);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A7A7A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentStep < 3 ? 'Next' : 'Submit Claim',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedClaimType != null;
      case 1:
        return _description != null && _description!.isNotEmpty;
      case 2:
        return _incidentDate != null && _incidentTime != null;
      case 3:
        return true;
      default:
        return false;
    }
  }

  Future<void> _submitClaim(ClaimsProvider claimsProvider) async {
    final incidentDateTime = DateTime(
      _incidentDate!.year,
      _incidentDate!.month,
      _incidentDate!.day,
      _incidentTime!.hour,
      _incidentTime!.minute,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submitting claim...')),
    );

    final result = await claimsProvider.submitClaim(
      type: _selectedClaimType!,
      description: _description!,
      incidentDate: incidentDateTime,
    );

    if (result != null && mounted) {
      final claim = Claim.fromJson(result);
      Navigator.pushReplacementNamed(
        context,
        '/claim-result',
        arguments: {
          'claim': claim,
          'approved': claim.status == 'APPROVED',
        },
      );
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;

        return Expanded(
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted || isCurrent
                      ? const Color(0xFF1A7A7A)
                      : Colors.grey[300],
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCompleted || isCurrent
                                ? Colors.white
                                : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              if (index < totalSteps - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? const Color(0xFF1A7A7A) : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _Step1SelectType extends StatelessWidget {
  final Function(String) onSelect;
  final String? selectedType;

  const _Step1SelectType({
    required this.onSelect,
    required this.selectedType,
  });

  @override
  Widget build(BuildContext context) {
    final claimTypes = [
      ('Accident', 'Me or my vehicle'),
      ('Extreme Weather', 'Heavy rain, storm, hail'),
      ('Curfew', 'Movement restrictions'),
      ('Vehicle Damage', 'Theft, vandalism, accident'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What happened?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the type of incident you want to claim for',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        ...claimTypes
            .map(
              (type) => _ClaimTypeCard(
                title: type.$1,
                subtitle: type.$2,
                isSelected: selectedType == type.$1,
                onTap: () => onSelect(type.$1),
              ),
            )
            .toList(),
      ],
    );
  }
}

class _ClaimTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClaimTypeCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF1A7A7A) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFF1A7A7A).withOpacity(0.05) : Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF1A7A7A) : Colors.grey[400]!,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Color(0xFF1A7A7A))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Step2Description extends StatelessWidget {
  final Function(String) onDescriptionChanged;
  final String? description;

  const _Step2Description({
    required this.onDescriptionChanged,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tell us what happened',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Provide details about the incident',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: onDescriptionChanged,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Describe the incident in detail...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }
}

class _Step3DateTime extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final Function(TimeOfDay) onTimeSelected;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;

  const _Step3DateTime({
    required this.onDateSelected,
    required this.onTimeSelected,
    required this.selectedDate,
    required this.selectedTime,
  });

  @override
  State<_Step3DateTime> createState() => _Step3DateTimeState();
}

class _Step3DateTimeState extends State<_Step3DateTime> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'When did it happen?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        // Date Picker
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF1A7A7A)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.selectedDate != null
                        ? DateFormat('dd MMM yyyy').format(widget.selectedDate!)
                        : 'Select date',
                    style: TextStyle(
                      color: widget.selectedDate != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Time Picker
        GestureDetector(
          onTap: _selectTime,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFF1A7A7A)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.selectedTime != null
                        ? widget.selectedTime!.format(context)
                        : 'Select time',
                    style: TextStyle(
                      color: widget.selectedTime != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      widget.onDateSelected(picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: widget.selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      widget.onTimeSelected(picked);
    }
  }
}

class _Step4Confirmation extends StatelessWidget {
  final String claimType;
  final String description;
  final DateTime? incidentDate;
  final TimeOfDay? incidentTime;

  const _Step4Confirmation({
    required this.claimType,
    required this.description,
    required this.incidentDate,
    required this.incidentTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Your Claim',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ConfirmationRow(label: 'Claim Type', value: claimType),
              Divider(color: Colors.grey[300]),
              Text(
                'Description',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(description),
              Divider(color: Colors.grey[300]),
              _ConfirmationRow(
                label: 'Date & Time',
                value: '${DateFormat('dd MMM yyyy').format(incidentDate!)} at ${incidentTime!.format(context)}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automatic Validation',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your claim will be validated against weather, location, and other factors automatically.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfirmationRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}
