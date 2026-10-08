String formatBRL(double value) {
  final cents = (value * 100).round();
  final intPart = (cents ~/ 100).toString();
  final dec = (cents % 100).toString().padLeft(2, '0');
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write('.');
    buf.write(intPart[i]);
  }
  return 'R\$$buf,$dec';
}

String formatPct(double p) => '${p.toStringAsFixed(2).replaceAll('.', ',')}%';

String _two(int n) => n.toString().padLeft(2, '0');

String formatTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

String formatDateTime(DateTime d) =>
    '${_two(d.day)}/${_two(d.month)}/${d.year} às ${formatTime(d)}';

/// "Hoje", "Ontem" ou "Seg, 05/10".
String formatDateHeader(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Ontem';
  const wd = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  return '${wd[d.weekday - 1]}, ${_two(d.day)}/${_two(d.month)}';
}

/// "+ R$ 10,00" / "- R$ 10,00"
String formatSigned(double v) =>
    '${v >= 0 ? '+' : '-'} ${formatBRL(v.abs())}';

/// "+1,25%" / "-0,80%"
String formatPctSigned(double p) =>
    '${p >= 0 ? '+' : '-'}${p.abs().toStringAsFixed(2).replaceAll('.', ',')}%';

/// Valor compacto para o eixo Y dos gráficos: "R$ 41,2k", "R$ 1,35M", "R$ 38,40".
String formatAxisBRL(double v) {
  final a = v.abs();
  String s;
  if (a >= 1000000) {
    s = '${(v / 1000000).toStringAsFixed(2).replaceAll('.', ',')}M';
  } else if (a >= 10000) {
    s = '${(v / 1000).toStringAsFixed(1).replaceAll('.', ',')}k';
  } else if (a >= 1000) {
    s = '${(v / 1000).toStringAsFixed(2).replaceAll('.', ',')}k';
  } else {
    s = v.toStringAsFixed(2).replaceAll('.', ',');
  }
  return 'R\$ $s';
}

/// Quantidade sem zeros sobrando: 0.04 -> "0,04", 12.0 -> "12".
String formatQty(double q) {
  var s = q.toStringAsFixed(6);
  s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return s.replaceAll('.', ',');
}

const _months = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

/// "out", "nov"...
String formatMonthShort(DateTime d) => _months[d.month - 1];

/// "07/10"
String formatDayMonth(DateTime d) => '${_two(d.day)}/${_two(d.month)}';
