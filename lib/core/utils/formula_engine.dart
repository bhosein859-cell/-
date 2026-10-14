/// ═══════════════════════════════════════════════════════════════
/// موتور فرمول‌های سفارشی KPI — مفسر عبارت ریاضی (خالص، آفلاین)
/// پشتیبانی: + - * / ( ) و متغیرهای تعریف‌شده توسط کاربر
/// روش: تبدیل به نماد لهستانی معکوس (Shunting-Yard) و ارزیابی پشته‌ای
/// ═══════════════════════════════════════════════════════════════
class FormulaEngine {
  /// ارزیابی عبارت؛ در صورت خطا `null` برمی‌گرداند
  static double? evaluate(String formula, Map<String, double> vars) {
    try {
      final tokens = _tokenize(formula, vars);
      final rpn = _toRpn(tokens);
      return _evalRpn(rpn);
    } catch (_) {
      return null;
    }
  }

  static bool isValid(String formula) =>
      evaluate(formula, {'x': 1, 'y': 1, 'a': 1, 'b': 1}) != null;

  // ── توکن‌سازی ──
  static List<_Tok> _tokenize(String s, Map<String, double> vars) {
    final out = <_Tok>[];
    var i = 0;
    s = s.replaceAll(' ', '').replaceAll('×', '*').replaceAll('÷', '/');
    while (i < s.length) {
      final c = s[i];
      if (RegExp(r'[0-9.]').hasMatch(c)) {
        var j = i;
        while (j < s.length && RegExp(r'[0-9.]').hasMatch(s[j])) {
          j++;
        }
        out.add(_Tok.num(double.parse(s.substring(i, j))));
        i = j;
      } else if (RegExp(r'[a-zA-Z\u0600-\u06FF_]').hasMatch(c)) {
        var j = i;
        while (j < s.length &&
            RegExp(r'[a-zA-Z0-9_\u0600-\u06FF]').hasMatch(s[j])) {
          j++;
        }
        final name = s.substring(i, j);
        final v = vars[name];
        if (v == null) throw FormatException('متغیر ناشناخته: $name');
        out.add(_Tok.num(v));
        i = j;
      } else if ('+-*/()'.contains(c)) {
        out.add(_Tok.op(c));
        i++;
      } else {
        throw FormatException('نویسه نامجاز: $c');
      }
    }
    return out;
  }

  static const Map<String, int> _prec = {'+': 1, '-': 1, '*': 2, '/': 2};

  static List<_Tok> _toRpn(List<_Tok> tokens) {
    final out = <_Tok>[];
    final stack = <_Tok>[];
    for (final t in tokens) {
      if (t.isNum) {
        out.add(t);
      } else if (t.value == '(') {
        stack.add(t);
      } else if (t.value == ')') {
        while (stack.isNotEmpty && stack.last.value != '(') {
          out.add(stack.removeLast());
        }
        if (stack.isEmpty) throw const FormatException('پرانتز نامتوازن');
        stack.removeLast();
      } else {
        while (stack.isNotEmpty &&
            stack.last.value != '(' &&
            (_prec[stack.last.value] ?? 0) >= (_prec[t.value] ?? 0)) {
          out.add(stack.removeLast());
        }
        stack.add(t);
      }
    }
    while (stack.isNotEmpty) {
      if (stack.last.value == '(') throw const FormatException('پرانتز نامتوازن');
      out.add(stack.removeLast());
    }
    return out;
  }

  static double _evalRpn(List<_Tok> rpn) {
    final stack = <double>[];
    for (final t in rpn) {
      if (t.isNum) {
        stack.add(t.num!);
      } else {
        if (stack.length < 2) throw const FormatException('عبارت ناقص');
        final b = stack.removeLast();
        final a = stack.removeLast();
        stack.add(switch (t.value) {
          '+' => a + b,
          '-' => a - b,
          '*' => a * b,
          '/' => b == 0 ? double.nan : a / b,
          _ => throw FormatException('عملگر ناشناخته'),
        });
      }
    }
    if (stack.length != 1) throw const FormatException('عبارت ناقص');
    return stack.single;
  }
}

class _Tok {
  const _Tok(this.value, {this.num});

  factory _Tok.num(double v) => _Tok('#', num: v);
  factory _Tok.op(String op) => _Tok(op);

  final String value;
  final double? num;

  bool get isNum => num != null;
}
