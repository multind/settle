import 'package:gtd_app/core/models/task_draft.dart';

/// 理清判定结果（规格 §5.2）：转 Task / 转 Project / 删除。
sealed class ClarifyDecision {
  const ClarifyDecision();
}

class ClarifyToTask extends ClarifyDecision {
  const ClarifyToTask(this.draft);
  final TaskDraft draft;
}

class ClarifyToProject extends ClarifyDecision {
  const ClarifyToProject({required this.name, this.goal});
  final String name;
  final String? goal;
}

class ClarifyDelete extends ClarifyDecision {}
