import 'package:flutter/material.dart';

/// Displays an offline curriculum picture for a word, with an emoji fallback
/// only when no verified picture mapping exists.
class TaskPicture extends StatelessWidget {
  final String word;
  final String fallbackEmoji;
  final double size;
  final BorderRadius borderRadius;

  const TaskPicture({
    super.key,
    required this.word,
    required this.fallbackEmoji,
    this.size = 96,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  static const Map<String, String> _assets = {
    // Grade 1 English picture vocabulary.
    'Apple': 'assets/images/tasks/english/apple.png',
    'Ball': 'assets/images/tasks/english/soccer_ball.png',
    'Cat': 'assets/images/tasks/english/cat.png',
    'Dog': 'assets/images/tasks/english/dog.png',
    'Egg': 'assets/images/tasks/english/egg.png',
    'Fish': 'assets/images/tasks/english/fish.png',
    'Goat': 'assets/images/tasks/english/goat.png',
    'Hat': 'assets/images/tasks/english/hat.png',
    'Ice cream': 'assets/images/tasks/english/ice_cream.png',
    'Jar': 'assets/images/tasks/english/jar.png',
    'Kite': 'assets/images/tasks/english/kite.png',
    'Lion': 'assets/images/tasks/english/lion.png',
    'Moon': 'assets/images/tasks/english/moon.png',
    'Nest': 'assets/images/tasks/english/nest.png',
    'Orange': 'assets/images/tasks/english/orange.png',
    'Pen': 'assets/images/tasks/english/pencil.png',
    'Pencil': 'assets/images/tasks/english/pencil.png',
    'Queen': 'assets/images/tasks/english/queen.png',
    'Rain': 'assets/images/tasks/english/rain.png',
    'Sun': 'assets/images/tasks/english/sun.png',
    'Tree': 'assets/images/tasks/english/tree.png',
    'Umbrella': 'assets/images/tasks/english/umbrella.png',
    'Van': 'assets/images/tasks/english/school_van.png',
    'Water': 'assets/images/tasks/english/water.png',
    'X-ray': 'assets/images/tasks/english/xray.png',
    'Yarn': 'assets/images/tasks/english/yarn.png',
    'Zebra': 'assets/images/tasks/english/zebra.png',

    // Grade 1 Sinhala picture vocabulary.
    'අඹ': 'assets/images/tasks/grade2/mango.png',
    'ආගම': 'assets/images/tasks/sinhala/respect_hands.png',
    'ඇණ': 'assets/images/tasks/sinhala/nail.png',
    'ඉර': 'assets/images/tasks/english/sun.png',
    'ඊතල': 'assets/images/tasks/sinhala/bow_arrow.png',
    'උදය': 'assets/images/tasks/grade2/sunrise.png',
    'ඌරා': 'assets/images/tasks/sinhala/pig.png',
    'කලය': 'assets/images/tasks/grade2/clay_pot.png',
    'ගම': 'assets/images/tasks/sinhala/village.png',
    'ජලය': 'assets/images/tasks/english/water.png',
    'ටයරය': 'assets/images/tasks/sinhala/tyre.png',
    'ඩොල්ෆින': 'assets/images/tasks/sinhala/dolphin.png',
    'දර': 'assets/images/tasks/sinhala/firewood.png',
    'බලය': 'assets/images/tasks/sinhala/strong_arm.png',
    'මල': 'assets/images/tasks/sinhala/flower.png',
    'රට': 'assets/images/tasks/sinhala/earth.png',
    'ලවන': 'assets/images/tasks/sinhala/salt.png',

    // Grade 2 vocabulary and pillam examples.
    'පිළිම': 'assets/images/tasks/grade2/statue.png',
    'කියවන්න': 'assets/images/tasks/grade2/storybook.png',
    'ලිවීම': 'assets/images/tasks/grade2/writing.png',
    'ගිහින්': 'assets/images/tasks/grade2/walking.png',
    'ආවා': 'assets/images/tasks/grade2/arriving_home.png',
    'ගෙදර': 'assets/images/tasks/grade2/house.png',
    'පොත': 'assets/images/tasks/grade2/books.png',
    'සෙල්ලම්': 'assets/images/tasks/grade2/soccer_ball.png',
    'කෑම': 'assets/images/tasks/grade2/meal.png',
    'ගස': 'assets/images/tasks/grade2/tree.png',
    'කාසිය': 'assets/images/tasks/grade2/coin.png',
    'කැලේ': 'assets/images/tasks/grade2/forest.png',
    'කිරි': 'assets/images/tasks/grade2/milk.png',
    'ගීතය': 'assets/images/tasks/grade2/music.png',
    'කුරුල්ලා': 'assets/images/tasks/grade2/bird.png',
    'කූඩය': 'assets/images/tasks/grade2/basket.png',
    'කෙසෙල්': 'assets/images/tasks/grade2/banana.png',
    'කේතලය': 'assets/images/tasks/grade2/kettle.png',
    'කොළඹ': 'assets/images/tasks/grade2/city.png',
    'කෝප්පය': 'assets/images/tasks/grade2/tea.png',
    'බත්': 'assets/images/tasks/grade2/rice.png',
  };

  static bool hasPicture(String word) => _assets.containsKey(word);

  @override
  Widget build(BuildContext context) {
    final path = _assets[word];
    if (path == null) return _fallback();
    return Semantics(
      image: true,
      label: word,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Image.asset(
          path,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() => SizedBox.square(
    dimension: size,
    child: Center(
      child: Text(fallbackEmoji, style: TextStyle(fontSize: size * 0.65)),
    ),
  );
}
