import 'package:flutter/material.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'dashboard.dart';
import 'player_provider.dart';
import 'models/hunter_profile.dart';
import 'ui/widgets/widgets.dart';
import 'ui/theme/app_text_styles.dart';
import 'ui/theme/app_colors.dart';
import 'package:provider/provider.dart';

// ============================================================
//  AWAKENING SCREEN — V2: Multi-Step Onboarding
//  Step 1: Player name
//  Step 2: Training days (min 3, max 7)
//  Step 3: Age, gender, body type, fitness goal
//  Step 4: Experience level → INITIALIZE SYSTEM
// ============================================================

class AwakeningScreen extends StatefulWidget {
  const AwakeningScreen({super.key});

  @override
  State<AwakeningScreen> createState() => _AwakeningScreenState();
}

class _AwakeningScreenState extends State<AwakeningScreen> {
  final _pageCtrl = PageController();
  int _currentStep = 0;

  // Step 1
  final _nameCtrl = TextEditingController();

  // Step 2
  final Set<int> _selectedDays = {};
  final _dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  // Weekday: Mon=1…Sun=7

  // Step 3
  int _age = 18;
  String _gender = '';
  String _bodyType = '';
  String _fitnessGoal = '';

  // Step 4
  String _experienceLevel = '';

  bool get _step1Valid => _nameCtrl.text.trim().isNotEmpty;
  bool get _step2Valid => _selectedDays.length >= 3;
  bool get _step3Valid =>
      _gender.isNotEmpty && _bodyType.isNotEmpty && _fitnessGoal.isNotEmpty;
  bool get _step4Valid => _experienceLevel.isNotEmpty;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageCtrl.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _initialize() async {
    final name = _nameCtrl.text.trim();
    final settings = HiveService.settings;
    final now = DateTime.now().toUtc();

    await settings.put('hasAwakened', true);
    await settings.put('playerName', name);
    await settings.put('awakeningDate', now.toIso8601String());

    // Build and save profile
    final profile = HunterProfile(
      age: _age,
      gender: _gender,
      bodyType: _bodyType,
      fitnessGoal: _fitnessGoal,
      experienceLevel: _experienceLevel,
      trainingDays: _selectedDays.toList()..sort(),
    );

    if (!mounted) return;
    final player = Provider.of<PlayerProvider>(context, listen: false);
    player.saveProfile(profile);

    try {
      await NotificationService.scheduleDailyNotifications();
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Dashboard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            _StepIndicator(current: _currentStep, total: 4),
            const SizedBox(height: 12),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _wrapPage(_buildStep1()),
                  _wrapPage(_buildStep2()),
                  _wrapPage(_buildStep3()),
                  _wrapPage(_buildStep4()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wrapPage(Widget child) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: child,
      );

  // ──────────────────────────────────────────────────────────────
  //  STEP 1: Name
  // ──────────────────────────────────────────────────────────────
  Widget _buildStep1() {
    return HolographicPanel(
      header: const SystemHeaderBar(label: 'PLAYER REGISTRATION'),
      emphasize: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Image.asset('assets/icons/app_icon.png',
                    fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You have Awakened.',
                  style: AppTextStyles.headerMedium.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'From today, your discipline defines you.\nComplete your Core Quests.\nRise in Level.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 28),
          Text(
            'HUNTER NAME',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter your hunter name...',
              hintStyle: TextStyle(color: Colors.white24),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.zero,
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue),
                borderRadius: BorderRadius.zero,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 28),
          _continueButton(_step1Valid, _next, '[→  CONTINUE]'),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  STEP 2: Training Days
  // ──────────────────────────────────────────────────────────────
  Widget _buildStep2() {
    return HolographicPanel(
      header: const SystemHeaderBar(label: 'TRAINING SCHEDULE'),
      emphasize: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECT YOUR TRAINING DAYS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose which days the System will assign directives.\nMinimum 3 days required.',
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 20),

          // Day grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.4,
            ),
            itemCount: 7,
            itemBuilder: (ctx, i) {
              final dayNum = i + 1; // Mon=1…Sun=7
              final selected = _selectedDays.contains(dayNum);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedDays.remove(dayNum);
                    } else {
                      _selectedDays.add(dayNum);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryBlue.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.03),
                    border: Border.all(
                      color: selected
                          ? AppColors.primaryBlue
                          : Colors.white.withValues(alpha: 0.12),
                      width: selected ? 1.5 : 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dayLabels[i],
                        style: TextStyle(
                          color: selected ? AppColors.primaryBlue : Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check,
                            size: 10, color: AppColors.primaryBlue),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          Text(
            '${_selectedDays.length} / 7 selected',
            style: TextStyle(
              color: _step2Valid ? AppColors.success : Colors.white38,
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          _continueButton(_step2Valid, _next, '[→  CONTINUE]'),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  STEP 3: Profile Details
  // ──────────────────────────────────────────────────────────────
  Widget _buildStep3() {
    return HolographicPanel(
      header: const SystemHeaderBar(label: 'HUNTER PROFILE'),
      emphasize: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYSTEM PROFILING',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This data calibrates your daily directives.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Age slider
          _fieldLabel('AGE'),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '$_age',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'years',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              Expanded(
                child: Slider(
                  value: _age.toDouble(),
                  min: 14,
                  max: 60,
                  divisions: 46,
                  activeColor: AppColors.primaryBlue,
                  inactiveColor: Colors.white12,
                  onChanged: (v) => setState(() => _age = v.round()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Gender
          _fieldLabel('GENDER'),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final g in ['male', 'female', 'other'])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _toggleChip(
                      g.toUpperCase(),
                      _gender == g,
                      () => setState(() => _gender = g),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Body type
          _fieldLabel('BODY TYPE'),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final bt in ['ectomorph', 'mesomorph', 'endomorph'])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _toggleChip(
                      bt.toUpperCase(),
                      _bodyType == bt,
                      () => setState(() => _bodyType = bt),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Fitness goal
          _fieldLabel('FITNESS GOAL'),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 3.5,
            children: [
              for (final g in const {
                'strength': '⚡ STRENGTH',
                'endurance': '🏃 ENDURANCE',
                'balance': '⚖ BALANCE',
                'weight_loss': '🔥 WEIGHT LOSS',
              }.entries)
                _toggleChip(
                  g.value,
                  _fitnessGoal == g.key,
                  () => setState(() => _fitnessGoal = g.key),
                ),
            ],
          ),

          const SizedBox(height: 24),
          _continueButton(_step3Valid, _next, '[→  CONTINUE]'),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  STEP 4: Experience & Final
  // ──────────────────────────────────────────────────────────────
  Widget _buildStep4() {
    return HolographicPanel(
      header: const SystemHeaderBar(label: 'EXPERIENCE LEVEL'),
      emphasize: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECT YOUR CLASS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Determines your initial directive difficulty.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),

          _experienceCard(
            'beginner',
            'BEGINNER',
            'New to training. Baseline targets.',
            '50 reps / 3km run',
            AppColors.success,
          ),
          const SizedBox(height: 10),
          _experienceCard(
            'intermediate',
            'INTERMEDIATE',
            'Regular training. Elevated targets.',
            '100 reps / 5km run',
            AppColors.warning,
          ),
          const SizedBox(height: 10),
          _experienceCard(
            'advanced',
            'ADVANCED',
            'Seasoned. Maximum output expected.',
            '150 reps / 10km run',
            AppColors.danger,
          ),

          const SizedBox(height: 24),
          _continueButton(_step4Valid, _initialize, '[⚡  INITIALIZE SYSTEM]'),
        ],
      ),
    );
  }

  Widget _experienceCard(
    String value,
    String label,
    String subtitle,
    String stats,
    Color color,
  ) {
    final selected = _experienceLevel == value;
    return GestureDetector(
      onTap: () => setState(() => _experienceLevel = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.10) : Colors.transparent,
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.12),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? color : Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  stats,
                  style: TextStyle(
                    color: selected ? color : Colors.white30,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_outline, color: color, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) => Text(
        label,
        style: TextStyle(
          color: Colors.white38,
          fontSize: 9,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
        ),
      );

  Widget _toggleChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryBlue.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(
            color: selected
                ? AppColors.primaryBlue
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primaryBlue : Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _continueButton(bool enabled, VoidCallback onTap, String label) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.primaryBlue.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: enabled ? AppColors.primaryBlue : Colors.white12,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: enabled ? AppColors.primaryBlue : Colors.white24,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  STEP INDICATOR
// ──────────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: List.generate(total * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIdx = i ~/ 2;
            return Expanded(
              child: Container(
                height: 1,
                color: stepIdx < current ? AppColors.primaryBlue : Colors.white12,
              ),
            );
          }
          // Dot
          final stepIdx = i ~/ 2;
          final done = stepIdx < current;
          final active = stepIdx == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: active ? 10 : 8,
            height: active ? 10 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? AppColors.primaryBlue
                  : active
                      ? AppColors.primaryBlue
                      : Colors.white12,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }
}