import 'package:flutter/material.dart';

const Color wtMint = Color(0xFF72F5C8);
const Color wtCyan = Color(0xFF20D7FF);
const Color wtBlue = Color(0xFF4B7BFF);
const Color wtPurple = Color(0xFF9A5BFF);
const Color wtBackground = Color(0xFF07111F);
const Color wtBackgroundTop = Color(0xFF0B1526);
const Color wtBackgroundMid = Color(0xFF0B1A2D);
const Color wtBackgroundBottom = Color(0xFF07111F);
const Color wtSurface = Color(0xFF0D1829);
const Color wtSurfaceElevated = Color(0xFF132238);
const Color wtGrid = Color(0x401A2A3D);
const Color wtWhite = Color(0xFFF5F7FB);
const Color wtTextMuted = Color(0xCCF5F7FB);

const LinearGradient wtAppBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: <Color>[
    wtBackgroundTop,
    wtBackgroundMid,
    wtBackgroundBottom,
  ],
);

const LinearGradient wtBoardGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: <Color>[
    Color(0xFF091523),
    Color(0xFF102238),
  ],
);

const LinearGradient wtTrailGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: <Color>[
    wtMint,
    wtCyan,
    wtBlue,
    wtPurple,
  ],
);

const Color wsInk = wtBackground;
const Color wsTeal = wtCyan;
const Color wsGold = wtBlue;
const Color wsCream = wtSurfaceElevated;
const Color wsMist = wtSurface;
const Color wsSage = wtMint;
const Color wsCoral = wtPurple;
