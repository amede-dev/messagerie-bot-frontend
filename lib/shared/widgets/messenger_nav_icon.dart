import 'package:flutter/material.dart';

class MessengerNavIcon extends StatelessWidget {
  const MessengerNavIcon({super.key, required this.selected});

  final bool selected;

  static const _noir = <double>[
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static const _vert = <double>[
    1,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(selected ? _vert : _noir),
      child: Image.asset(
        'assets/images/messangeur.png',
        width: selected ? 26 : 24,
        height: selected ? 26 : 24,
        fit: BoxFit.contain,
      ),
    );
  }
}
