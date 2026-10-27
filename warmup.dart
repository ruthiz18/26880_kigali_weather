Future<String> orderBrochette() async {
  await Future.delayed(const Duration(seconds: 3));
  return 'Your brochette is ready';
}

void main() async {
  print('1. You order a brochette');
  final order = orderBrochette();
  print('2. While it cooks, you chat with your friends');
  final food = order;
  print('3. $food');
  print('4. You eat');
}