/// Duas letras que identificam a pessoa no avatar: a primeira do primeiro
/// nome e a do último sobrenome ("Lucas Brun" → "LB"). Com um nome só,
/// as duas primeiras letras dele ("Lucas" → "LU").
String initialsOf(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) {
    final w = words.first;
    return (w.length == 1 ? w : w.substring(0, 2)).toUpperCase();
  }
  return (words.first[0] + words.last[0]).toUpperCase();
}
