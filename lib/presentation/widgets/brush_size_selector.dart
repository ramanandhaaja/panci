import 'package:flutter/material.dart';

/// A widget that displays brush size options for drawing.
///
/// The user can select a brush size by tapping on it, and the currently
/// selected size is visually indicated with a highlighted background.
class BrushSizeSelector extends StatelessWidget {
  /// Creates a brush size selector widget.
  ///
  /// The [selectedSize] parameter indicates which size is currently selected.
  /// The [onSizeSelected] callback is triggered when a user taps on a size option.
  const BrushSizeSelector({
    super.key,
    required this.selectedSize,
    required this.onSizeSelected,
  });

  /// The currently selected brush size.
  final double selectedSize;

  /// Callback function triggered when a brush size is selected.
  final ValueChanged<double> onSizeSelected;

  /// Available brush sizes for drawing.
  static const List<double> availableSizes = [2.0, 4.0, 8.0, 12.0, 16.0];

  /// Labels for each brush size option.
  static const List<String> sizeLabels = ['XS', 'S', 'M', 'L', 'XL'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: availableSizes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final size = availableSizes[index];
          final label = sizeLabels[index];
          final isSelected = size == selectedSize;

          return GestureDetector(
            onTap: () => onSizeSelected(size),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Visual representation of the brush size
                  Container(
                    width: size * 2,
                    height: size * 2,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Size label
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
