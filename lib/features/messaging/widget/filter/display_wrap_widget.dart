import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DisplayWrapWidget extends StatefulWidget {
  const DisplayWrapWidget({
    super.key,
    required this.items,
    this.initialSelectedIndexes,
    this.onSelectionChanged,
  });

  final List<String> items;

  final List<int>? initialSelectedIndexes;

  final ValueChanged<List<String>>? onSelectionChanged;

  @override
  State<DisplayWrapWidget> createState() => _DisplayWrapWidgetState();
}

class _DisplayWrapWidgetState extends State<DisplayWrapWidget> {
  late final Set<int> _selectedIndexes;

  @override
  void initState() {
    super.initState();
    _selectedIndexes = {
      if (widget.initialSelectedIndexes != null)
        ...widget.initialSelectedIndexes!.where(
          (i) => i >= 0 && i < widget.items.length,
        ),
    };
  }

  void _toggleIndex(int index) {
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        _selectedIndexes.add(index);
      }
    });

    final selectedValues = _selectedIndexes
        .map((i) => widget.items[i])
        .toList();
    widget.onSelectionChanged?.call(selectedValues);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6.w,
      runSpacing: 10.h,
      children: List.generate(widget.items.length, (index) {
        final value = widget.items[index];
        final isSelected = _selectedIndexes.contains(index);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _toggleIndex(index),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontSize: 14.sp,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ),
        );
      }),
    );
  }
}
