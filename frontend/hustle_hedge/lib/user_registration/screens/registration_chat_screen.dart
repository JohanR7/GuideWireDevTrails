import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../controllers/registration_controller.dart';
import '../models/registration_questions.dart';
import '../widgets/typing_text_widget.dart';
import '../widgets/question_input_widget.dart';
import '../widgets/registration_progress_bar.dart';
import '../widgets/answered_question_bubble.dart';
import 'registration_complete_screen.dart';

class RegistrationChatScreen extends StatefulWidget {
  const RegistrationChatScreen({super.key});

  @override
  State<RegistrationChatScreen> createState() => _RegistrationChatScreenState();
}

class _RegistrationChatScreenState extends State<RegistrationChatScreen> {
  final RegistrationController _controller = RegistrationController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    if (!mounted) return;
    setState(() {});

    if (_controller.isComplete) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, animation, __) => FadeTransition(
                opacity: animation,
                child: RegistrationCompleteScreen(
                  data: _controller.registrationData,
                ),
              ),
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      });
    }

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _controller.currentQuestion;
    final answered = _controller.answers;
    final activeQuestions =
        RegistrationQuestions.getActiveQuestions(answered);
    final displayedPast = activeQuestions
        .take(_controller.currentIndex)
        .where((q) => answered.containsKey(q.id))
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'H',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('HustleHedge'),
          ],
        ),
        leading: _controller.canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: _controller.goBack,
              )
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: RegistrationProgressBar(
              progress: _controller.progress,
              current: _controller.currentIndex + 1,
              total: _controller.totalQuestions,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Chat scroll area
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              children: [
                // Welcome message
                _WelcomeBubble(),
                const SizedBox(height: 16),

                // Past answered questions
                ...displayedPast.map((q) => AnsweredQuestionBubble(
                      question: q,
                      answer: answered[q.id] ?? '',
                    )),

                // Current question + typing state
                if (current != null) ...[
                  // Current bot question
                  _CurrentQuestionBubble(
                    question: current,
                    isTyping: _controller.isTyping,
                  ),
                ],

                if (_controller.isTyping) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: TypingIndicator(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),

          // Input area pinned at bottom
          if (current != null && !_controller.isTyping)
            _InputArea(
              key: ValueKey(current.id),
              controller: _controller,
            ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

// --- Sub-widgets ---

class _WelcomeBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(right: 48),
      decoration: BoxDecoration(
        color: AppTheme.secondaryMuted,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: const Text(
        "Hey! I'm Hedge 👋\nI'll help you set up your gig worker insurance. It only takes a couple of minutes.",
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondary,
          fontFamily: AppTheme.fontFamily,
          height: 1.5,
        ),
      ),
    );
  }
}

class _CurrentQuestionBubble extends StatelessWidget {
  final dynamic question;
  final bool isTyping;

  const _CurrentQuestionBubble({
    required this.question,
    required this.isTyping,
  });

  @override
  Widget build(BuildContext context) {
    if (isTyping) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(right: 48, bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryMuted,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TypingTextWidget(
            text: question.message,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              height: 1.45,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          if (question.subText != null) ...[
            const SizedBox(height: 4),
            Text(
              question.subText!,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final RegistrationController controller;

  const _InputArea({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final question = controller.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: QuestionInputWidget(
        question: question,
        initialValue: controller.getAnswer(question.id),
        onSubmit: (value) => controller.submitAnswer(question.id, value),
      ),
    );
  }
}