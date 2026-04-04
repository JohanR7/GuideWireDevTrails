import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../models/registration_question.dart';

class QuestionInputWidget extends StatefulWidget {
  final RegistrationQuestion question;
  final String? initialValue;
  final void Function(String value) onSubmit;

  const QuestionInputWidget({
    super.key,
    required this.question,
    this.initialValue,
    required this.onSubmit,
  });

  @override
  State<QuestionInputWidget> createState() => _QuestionInputWidgetState();
}

class _QuestionInputWidgetState extends State<QuestionInputWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final TextEditingController _textController = TextEditingController();
  String? _selectedChoice;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    if (widget.initialValue != null) {
      _textController.text = widget.initialValue!;
      _selectedChoice = widget.initialValue;
    }

    // Delay to let the bot message finish typing first
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final q = widget.question;
    if (q.type == QuestionType.singleChoice) {
      if (_selectedChoice == null) {
        setState(() => _errorText = 'Please select an option');
        return;
      }
      widget.onSubmit(_selectedChoice!);
      return;
    }

    final value = _textController.text.trim();
    if (!q.isOptional && value.isEmpty) {
      setState(() => _errorText = 'This field is required');
      return;
    }

    // Aadhaar validation
    if (q.type == QuestionType.idNumber) {
      final digits = value.replaceAll(' ', '');
      if (digits.length != 12 || int.tryParse(digits) == null) {
        setState(() => _errorText = 'Please enter a valid 12-digit Aadhaar number');
        return;
      }
    }

    setState(() => _errorText = null);
    widget.onSubmit(value.isEmpty ? '—' : value);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInput(),
            if (_errorText != null) ...[
              const SizedBox(height: 6),
              Text(
                _errorText!,
                style: const TextStyle(
                  color: AppTheme.error,
                  fontSize: 12,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (widget.question.type != QuestionType.singleChoice)
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Continue'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    switch (widget.question.type) {
      case QuestionType.singleChoice:
        return _buildChoices();
      case QuestionType.date:
        return _buildDateField();
      case QuestionType.idNumber:
        return _buildAadhaarField();
      case QuestionType.numberInput:
        return _buildNumberField();
      case QuestionType.amount:
        return _buildAmountField();
      case QuestionType.address:
        return _buildAddressField();
      default:
        return _buildTextField();
    }
  }

  Widget _buildChoices() {
    return Column(
      children: widget.question.choices!.map((choice) {
        final isSelected = _selectedChoice == choice;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedChoice = choice);
            Future.delayed(const Duration(milliseconds: 200), () => _submit());
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.secondary : AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.secondary : AppTheme.divider,
                width: isSelected ? 0 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    choice,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppTheme.fontFamily,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _textController,
      autofocus: true,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(
        fontSize: 15,
        fontFamily: AppTheme.fontFamily,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(hintText: widget.question.inputHint),
      onSubmitted: (_) => _submit(),
    );
  }

  Widget _buildAddressField() {
    return TextField(
      controller: _textController,
      autofocus: true,
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(
        fontSize: 15,
        fontFamily: AppTheme.fontFamily,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(hintText: widget.question.inputHint),
    );
  }

  Widget _buildDateField() {
    return TextField(
      controller: _textController,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _DateInputFormatter(),
      ],
      style: const TextStyle(
        fontSize: 15,
        fontFamily: AppTheme.fontFamily,
        color: AppTheme.textPrimary,
        letterSpacing: 2,
      ),
      decoration: InputDecoration(
        hintText: widget.question.inputHint,
        suffixIcon: const Icon(Icons.calendar_today_outlined,
            color: AppTheme.secondary, size: 20),
      ),
      onSubmitted: (_) => _submit(),
    );
  }

  Widget _buildAadhaarField() {
    return TextField(
      controller: _textController,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(12),
        _AadhaarInputFormatter(),
      ],
      style: const TextStyle(
        fontSize: 15,
        fontFamily: AppTheme.fontFamily,
        color: AppTheme.textPrimary,
        letterSpacing: 3,
      ),
      decoration: InputDecoration(
        hintText: widget.question.inputHint,
        suffixIcon: const Icon(Icons.credit_card_outlined,
            color: AppTheme.secondary, size: 20),
      ),
      onSubmitted: (_) => _submit(),
    );
  }

  Widget _buildNumberField() {
    return TextField(
      controller: _textController,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
        fontSize: 15,
        fontFamily: AppTheme.fontFamily,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(hintText: widget.question.inputHint),
      onSubmitted: (_) => _submit(),
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _textController,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
        fontSize: 15,
        fontFamily: AppTheme.fontFamily,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: widget.question.inputHint,
        prefixText: '₹ ',
        prefixStyle: const TextStyle(
          color: AppTheme.secondary,
          fontWeight: FontWeight.w600,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
      onSubmitted: (_) => _submit(),
    );
  }
}

// --- Formatters ---

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length > 8) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _AadhaarInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    if (digits.length > 12) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}