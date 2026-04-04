import '../models/registration_question.dart';

class RegistrationQuestions {
  static const List<RegistrationQuestion> all = [
    RegistrationQuestion(
      id: 'full_name',
      message: "Let's start with the basics.\nWhat's your full name?",
      subText: "As it appears on your Aadhaar card",
      type: QuestionType.text,
      inputHint: 'Your full name',
    ),
    RegistrationQuestion(
      id: 'residential_address',
      message: "And where do you live?\nShare your residential address.",
      subText: "We'll use this for your policy",
      type: QuestionType.address,
      inputHint: 'Street, City, State, PIN',
    ),
    RegistrationQuestion(
      id: 'delivery_partner_id',
      message: "What's your Delivery Partner ID?",
      subText: "The unique ID assigned to you by your platform",
      type: QuestionType.text,
      inputHint: 'e.g. SW-294821',
    ),
    RegistrationQuestion(
      id: 'platform',
      message: "Which platform do you deliver for?",
      type: QuestionType.singleChoice,
      choices: ['Swiggy', 'Zomato', 'Both'],
    ),
    RegistrationQuestion(
      id: 'dob',
      message: "What's your date of birth?",
      type: QuestionType.date,
      inputHint: 'DD / MM / YYYY',
    ),
    RegistrationQuestion(
      id: 'aadhar',
      message: "Please enter your\nAadhaar number.",
      subText: "12-digit number on your Aadhaar card",
      type: QuestionType.idNumber,
      inputHint: 'XXXX XXXX XXXX',
    ),
    RegistrationQuestion(
      id: 'vehicle_type',
      message: "What kind of vehicle\ndo you ride?",
      type: QuestionType.singleChoice,
      choices: ['Bicycle', 'Scooter / Bike', 'Car', 'Three-Wheeler'],
    ),
    RegistrationQuestion(
      id: 'driving_license',
      message: "What's your Driving License number?",
      subText: "Not required for bicycle riders",
      type: QuestionType.text,
      inputHint: 'e.g. TN0120240012345',
      isOptional: true,
    ),
    RegistrationQuestion(
      id: 'late_delivery',
      message: "Have you had any\nlate deliveries before?",
      type: QuestionType.singleChoice,
      choices: ['Yes', 'No'],
    ),
    RegistrationQuestion(
      id: 'late_delivery_count',
      message: "Roughly how many\nlate deliveries have you had?",
      subText: "An approximate number is fine",
      type: QuestionType.numberInput,
      inputHint: 'e.g. 5',
      dependsOnId: 'late_delivery',
      dependsOnValue: 'Yes',
    ),
    RegistrationQuestion(
      id: 'weekly_income',
      message: "How much do you earn\nfrom delivering each week?",
      subText: "Approximate amount in ₹",
      type: QuestionType.amount,
      inputHint: '₹ Weekly earnings',
    ),
    RegistrationQuestion(
      id: 'has_other_jobs',
      message: "Do you have any other jobs\napart from delivering?",
      type: QuestionType.singleChoice,
      choices: ['Yes', 'No'],
    ),
    RegistrationQuestion(
      id: 'other_jobs_description',
      message: "What other work do you do?",
      subText: "Brief description is fine",
      type: QuestionType.text,
      inputHint: 'e.g. Part-time driver, shop helper',
      dependsOnId: 'has_other_jobs',
      dependsOnValue: 'Yes',
    ),
  ];

  /// Filter questions based on current answers (handles conditional questions)
  static List<RegistrationQuestion> getActiveQuestions(
      Map<String, String> answers) {
    return all.where((q) {
      if (q.dependsOnId == null) return true;
      return answers[q.dependsOnId] == q.dependsOnValue;
    }).toList();
  }
}