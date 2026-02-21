import 'package:flutter/material.dart';

class EqualizerLoadingView extends StatefulWidget {
  const EqualizerLoadingView({super.key});

  @override
  State<EqualizerLoadingView> createState() => _EqualizerLoadingViewState();
}

class _EqualizerLoadingViewState extends State<EqualizerLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(5, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _EqualizerBar(
                  controller: _controller,
                  index: i,
                  color: colorScheme.primary,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            'niessl.org recipes',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EqualizerBar extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Color color;

  const _EqualizerBar({
    required this.controller,
    required this.index,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          index * 0.15,
          index * 0.15 + 0.35,
          curve: Curves.easeInOut,
        ),
      ),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Transform.scale(
        scaleY: animation.value,
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 5,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
      ),
    );
  }
}
