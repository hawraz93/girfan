import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../recurring/recurring_screen.dart';
import '../recurring/recurring_sheet.dart';
import '../widgets/widgets.dart';
import 'debt_sheet.dart';
import 'debts_tab.dart';
import 'goal_sheet.dart';
import 'goals_tab.dart';

/// Everything that is planned rather than spent today: fixed monthly items,
/// debts, and things you are saving up for.
class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  int _tab = 0;

  static const _titles = [S.recurring, S.debts, S.goalsTitle];

  void _add() {
    switch (_tab) {
      case 0:
        showRecurringSheet(context);
      case 1:
        showDebtSheet(context);
      default:
        showGoalSheet(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_titles[_tab],
                        style: context.tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  RoundIconButton(Icons.add_rounded, onTap: _add),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentTabs(
                labels: const [S.recurring, S.debts, S.goals],
                index: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [RecurringTab(), DebtsTab(), GoalsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
