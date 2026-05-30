import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LayerChipBar extends StatelessWidget {
  const LayerChipBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < labels.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppTheme.spaceSM),
                    _LayerChip(
                      label: labels[i],
                      selected: i == selectedIndex,
                      onTap: () => onSelect(i),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  const _LayerChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.chipBgOnDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMD - 2, vertical: AppTheme.spaceXS + 1),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: selected ? AppTheme.textOnDark : AppTheme.textOnDarkMid,
                ),
          ),
        ),
      ),
    );
  }
}
