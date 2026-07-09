import 'package:flutter/material.dart';
import '../utils/recipe_photo.dart';

/// A recipe photo that NEVER looks broken.
///
/// - shows the matched Unsplash photo when it loads,
/// - a soft gradient while loading,
/// - and, if the network image fails, an appetising gradient + food emoji
///   derived from the recipe title (no ugly "no image" placeholder).
class RecipeImage extends StatelessWidget {
  final String title;
  final String? seed;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? radius;
  final double emojiSize;

  const RecipeImage({
    super.key,
    required this.title,
    this.seed,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius,
    this.emojiSize = 40,
  });

  // Warm, appetising gradient for the fallback, varied by title.
  static const _gradients = [
    [Color(0xFFFFE0B2), Color(0xFFFFCC80)], // peach
    [Color(0xFFC8E6C9), Color(0xFFA5D6A7)], // green
    [Color(0xFFB3E5FC), Color(0xFF81D4FA)], // blue
    [Color(0xFFF8BBD0), Color(0xFFF48FB1)], // pink
    [Color(0xFFE1BEE7), Color(0xFFCE93D8)], // purple
    [Color(0xFFFFF9C4), Color(0xFFFFF176)], // yellow
  ];

  Widget _fallback() {
    final g = _gradients[(seed ?? title).hashCode.abs() % _gradients.length];
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: g,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        RecipePhoto.emojiForTitle(title),
        style: TextStyle(fontSize: emojiSize),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final img = Image.network(
      RecipePhoto.forTitle(title, seed: seed),
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: const Color(0xFFF1EFEC),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFBDBDBD),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => _fallback(),
    );

    if (radius != null) {
      return ClipRRect(borderRadius: radius!, child: img);
    }
    return img;
  }
}
