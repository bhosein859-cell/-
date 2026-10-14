import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../data/database/database_helper.dart';
import '../../data/models/action_item.dart';
import '../../data/models/attachment.dart';
import '../../data/models/problem.dart';
import '../../data/repositories/problem_repository.dart';
import 'level1_state.dart';

/// شمارنده‌ی نسخه — با تغییر آن، لیست «پروژه‌های فعال» و داشبورد
/// به‌صورت خودکار تازه‌سازی می‌شوند (یکپارچگی با داشبورد).
final problemsVersionProvider = StateProvider<int>((ref) => 0);

/// مدیریت حالت ویزارد ۴ مرحله‌ای سطح ۱ با Riverpod.
class Level1WizardNotifier extends Notifier<Level1WizardState> {
  @override
  Level1WizardState build() => Level1WizardState();

  ProblemRepository get _repo => ref.read(problemRepositoryProvider);

  /// به‌روزرسانی عمومی وضعیت
  void update(Level1WizardState Function(Level1WizardState s) f) =>
      state = f(state);

  void setStep(int step) => update((s) => s.copyWith(step: step));

  // ════════════════ مرحله ۱ → ثبت مسئله + پیوست‌ها ════════════════

  /// ساخت رکورد در جدول Problems (با Level=1) و کپی پیوست‌ها در
  /// پوشه‌ی attachments + درج در جدول Attachments.
  Future<String?> createProblem() async {
    if (state.title.trim().isEmpty) return 'عنوان مشکل الزامی است.';
    update((s) => s.copyWith(busy: true));
    try {
      final id = await _repo.insertProblem(Problem(
        title: state.title.trim(),
        description:
            state.description.trim().isEmpty ? null : state.description.trim(),
        level: 1, // 🔒 سطح ۱: حل سریع
        status: ProblemStatus.open,
        priority: state.priority,
        ownerId: 1,
        createdBy: 1,
        metadata: {
          'location': state.location,
          'five_whys': <String>[],
        },
      ));

      // کپی فایل‌های پیوست به پوشه‌ی داده و ثبت در دیتابیس
      final attachmentsDir = await DatabaseHelper.instance.attachmentsDir;
      for (final picked in state.pendingAttachments) {
        final base = p.basename(picked.path);
        final storedName =
            '${DateTime.now().millisecondsSinceEpoch}_$base';
        final dest = File(p.join(attachmentsDir.path, storedName));
        await File(picked.path).copy(dest.path);
        await _repo.insertAttachment(Attachment(
          problemId: id,
          fileName: base,
          filePath: storedName, // مسیر نسبی — انتقال‌پذیر در .psp
          mimeType: 'image/*',
          sizeBytes: await dest.length(),
          uploadedBy: 1,
        ));
      }

      ref.read(problemsVersionProvider.notifier).state++;
      update((s) => s.copyWith(busy: false, problemId: id));
      return null;
    } catch (e) {
      update((s) => s.copyWith(busy: false));
      return 'خطا در ثبت مشکل: $e';
    }
  }

  // ════════════════ مرحله ۲ → ذخیره‌ی ۵ چرا ════════════════

  /// ذخیره‌ی پاسخ‌های ۵ چرا به‌صورت آرایه‌ی JSON در ستون metadata جدول Problems.
  Future<String?> saveWhys() async {
    final id = state.problemId;
    if (id == null) return 'ابتدا مشکل را ثبت کنید.';
    await _repo.mergeProblemMetadata(id, {
      'five_whys': state.whys,
      'location': state.location,
    });
    update((s) => s.copyWith(clearRetryNotice: true));
    return null;
  }

  // ════════════════ مرحله ۳ → اقدام فوری ════════════════

  /// درج/به‌روزرسانی رکورد در جدول Actions.
  Future<String?> saveAction() async {
    final id = state.problemId;
    if (id == null) return 'مسئله‌ای ثبت نشده است.';

    final doneBy = state.actionBy.trim().isEmpty ? '—' : state.actionBy.trim();

    if (state.actionId == null) {
      final actionId = await _repo.insertAction(ActionItem(
        problemId: id,
        title: state.actionTitle.trim(),
        phase: 'Act', // اقدام فوری سطح ۱
        assigneeId: 1,
        status: state.actionStatus,
        progress: state.actionStatus == ActionStatus.done ? 100 : 50,
        metadata: {
          'done_by': doneBy,
          'done_at': state.actionAt.toIso8601String(),
        },
      ));
      update((s) => s.copyWith(actionId: actionId));
    } else {
      await _repo.updateAction(state.actionId!, {
        'title': state.actionTitle.trim(),
        'status': state.actionStatus,
        'progress': state.actionStatus == ActionStatus.done ? 100 : 50,
        'metadata':
            '{"done_by":"$doneBy","done_at":"${state.actionAt.toIso8601String()}"}',
      });
    }

    // مسئله پس از اقدام، «در حال انجام» می‌شود
    await _repo.updateProblem(id, {'status': ProblemStatus.inProgress});
    return null;
  }

  // ════════════════ مرحله ۴ → بستن و تایید ════════════════

  /// اگر کاربر تایید کرد: وضعیت مسئله «بسته» + زمان حل + اقدام «انجام‌شده».
  Future<String?> closeProblem() async {
    final id = state.problemId;
    if (id == null) return 'مسئله‌ای ثبت نشده است.';

    await _repo.updateProblem(id, {
      'status': ProblemStatus.closed,
      'resolved_at': DateTime.now().toIso8601String(),
    });
    await _repo.mergeProblemMetadata(id, {
      'verified': true,
      'five_whys': state.whys,
    });
    if (state.actionId != null) {
      await _repo.updateAction(state.actionId!, {
        'status': ActionStatus.done,
        'progress': 100,
        'completed_at': DateTime.now().toIso8601String(),
      });
    }

    ref.read(problemsVersionProvider.notifier).state++;
    update((s) => s.copyWith(verified: true));
    return null;
  }

  /// انتخاب «خیر» در مرحله ۴ → بازگشت خودکار به مرحله ۲ با پیام راهنما.
  void markNotVerified() {
    update((s) => s.copyWith(
          verified: false,
          retryNotice: 'لطفاً ریشه‌یابی را دوباره بررسی کنید. '
              'مشکل هنوز برطرف نشده است.',
        ));
  }

  /// پاسخ «خیر» — وضعیت را علامت‌گذاری و صفحه را به مرحله‌ی ۲ برمی‌گرداند.
  /// پوسته‌ی ویزارد با شنیدن تغییر [Level1WizardState.step] صفحه را جابه‌جا می‌کند.
  void onAnswerNo() {
    markNotVerified();
    setStep(1);
  }
}

/// ارائه‌دهنده‌ی سراسری ویزارد سطح ۱
final level1WizardProvider =
    NotifierProvider<Level1WizardNotifier, Level1WizardState>(
        Level1WizardNotifier.new);
