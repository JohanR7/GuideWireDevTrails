enum QuestionType {
  text,
  address,
  date,
  singleChoice,
  numberInput,
  idNumber,
  amount,
}

class RegistrationQuestion {
  final String id;
  final String message;       // The bot's typed-out message
  final String? subText;      // Optional hint below the message
  final QuestionType type;
  final List<String>? choices; // For singleChoice type
  final String? inputHint;
  final bool isOptional;
  final String? dependsOnId;   // Show only if this question id was answered with [dependsOnValue]
  final String? dependsOnValue;

  const RegistrationQuestion({
    required this.id,
    required this.message,
    this.subText,
    required this.type,
    this.choices,
    this.inputHint,
    this.isOptional = false,
    this.dependsOnId,
    this.dependsOnValue,
  });
}