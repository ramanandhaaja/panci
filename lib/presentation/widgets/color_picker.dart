import 'package:flutter/material.dart';

/// A widget that displays a horizontal list of color options for drawing.
///
/// The user can select a color by tapping on it, and the currently selected
/// color is visually indicated with a border and check icon.
class ColorPicker extends StatelessWidget {
  /// Creates a color picker widget.
  ///
  /// The [selectedColor] parameter indicates which color is currently selected.
  /// The [onColorSelected] callback is triggered when a user taps on a color.
  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  /// The currently selected color.
  final Color selectedColor;

  /// Callback function triggered when a color is selected.
  final ValueChanged<Color> onColorSelected;

  /// Available colors for drawing.
  static const List<Color> availableColors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.grey,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: availableColors.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final color = availableColors[index];
          final isSelected = color == selectedColor;

          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.grey.shade300,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: _getContrastingColor(color),
                      size: 24,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  /// Returns a contrasting color (white or black) based on the brightness
  /// of the provided color for better visibility of the check icon.
  Color _getContrastingColor(Color color) {
    // Calculate relative luminance
    final red = (color.r * 255.0).round().clamp(0, 255);
    final green = (color.g * 255.0).round().clamp(0, 255);
    final blue = (color.b * 255.0).round().clamp(0, 255);
    final luminance = (0.299 * red + 0.587 * green + 0.114 * blue) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
