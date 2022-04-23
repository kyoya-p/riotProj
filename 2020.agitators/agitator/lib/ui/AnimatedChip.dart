import 'package:flutter/material.dart';

typedef Builder = Widget Function(
    BuildContext context, Animation<Color?> color);

class AnimatedChip extends StatefulWidget {
  AnimatedChip(
      {required this.builder, required this.ago, this.duration = 15000});

  final Builder builder;
  final int ago;
  final int duration;

  @override
  _AnimatedChipState createState() {
    return _AnimatedChipState();
  }
}

class _AnimatedChipState extends State<AnimatedChip>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _color;

  @override
  void initState() {
    int dur = widget.duration - widget.ago;
    if (dur < 0) dur = 0;
    _animationController =
        AnimationController(duration: Duration(milliseconds: dur), vsync: this);
    _color = ColorTween(begin: Colors.blue, end: Colors.grey[200])
        .animate(_animationController);
    _animationController.forward(from: widget.ago / widget.duration);
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _animationController,
        builder: (BuildContext context, Widget? child) {
          return widget.builder(context, _color);
        });
  }

  start() {
    setState(() {
      _animationController.forward(from: 0.0);
    });
  }
}
