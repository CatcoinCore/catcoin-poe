import 'package:flutter/material.dart';

import 'arrow_escape_models.dart';

/// Campaign levels: polyline arrows (tail → head). Mechanics match Arrow Escape–
/// style puzzles [tap = escape along head ray if clear].
final List<ArrowEscapeLevelDef> kArrowEscapeCampaignLevels = [
  ArrowEscapeLevelDef(
    name: 'Tutorial',
    rows: 6,
    cols: 6,
    paths: [
      ArrowPathDef(cells: [(2, 1), (2, 2), (2, 3)], headDir: ArrowEscapeDir.right),
    ],
  ),
  ArrowEscapeLevelDef(
    name: 'Two-step',
    rows: 6,
    cols: 6,
    paths: [
      ArrowPathDef(cells: [(1, 2)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(4, 2)], headDir: ArrowEscapeDir.down),
    ],
  ),
  ArrowEscapeLevelDef(
    name: 'L-blocks',
    rows: 7,
    cols: 7,
    paths: [
      ArrowPathDef(cells: [(2, 1), (2, 2), (3, 2)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(4, 4), (4, 5), (3, 5)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(5, 1), (5, 2)], headDir: ArrowEscapeDir.right),
    ],
  ),
  ArrowEscapeLevelDef(
    name: 'Corridor',
    rows: 7,
    cols: 8,
    paths: [
      ArrowPathDef(cells: [(3, 1), (3, 2), (3, 3)], headDir: ArrowEscapeDir.right),
      ArrowPathDef(cells: [(3, 6)], headDir: ArrowEscapeDir.right),
      ArrowPathDef(cells: [(1, 4), (2, 4)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(5, 4)], headDir: ArrowEscapeDir.up),
    ],
  ),
  ArrowEscapeLevelDef(
    name: 'Weave',
    rows: 8,
    cols: 8,
    paths: [
      ArrowPathDef(cells: [(2, 2), (2, 3), (2, 4), (3, 4)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(5, 5), (5, 4), (5, 3), (4, 3)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(1, 6), (2, 6)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(6, 1), (6, 2)], headDir: ArrowEscapeDir.right),
      ArrowPathDef(cells: [(4, 6)], headDir: ArrowEscapeDir.right),
    ],
  ),
  ArrowEscapeLevelDef(
    name: 'Spiral bite',
    rows: 8,
    cols: 8,
    paths: [
      ArrowPathDef(cells: [(3, 3), (3, 4), (4, 4), (4, 3), (5, 3)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(1, 5), (2, 5), (3, 5)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(6, 6), (6, 5), (5, 5)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(2, 1), (3, 1), (4, 1)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(5, 6)], headDir: ArrowEscapeDir.right),
    ],
  ),
  ArrowEscapeLevelDef(
    name: 'Locks',
    rows: 8,
    cols: 9,
    paths: [
      ArrowPathDef(cells: [(3, 2), (3, 3), (3, 4)], headDir: ArrowEscapeDir.right),
      ArrowPathDef(cells: [(3, 7)], headDir: ArrowEscapeDir.right),
      ArrowPathDef(cells: [(1, 5)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(6, 5)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(4, 1), (4, 2)], headDir: ArrowEscapeDir.right),
      ArrowPathDef(cells: [(5, 6), (4, 6)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(2, 6), (2, 7)], headDir: ArrowEscapeDir.right),
    ],
  ),
  ArrowEscapeLevelDef(
    name: 'Hairpins',
    rows: 9,
    cols: 9,
    paths: [
      ArrowPathDef(cells: [(4, 2), (4, 3), (5, 3), (5, 4), (5, 5)], headDir: ArrowEscapeDir.right),
      ArrowPathDef(cells: [(2, 6), (3, 6), (3, 5), (3, 4)], headDir: ArrowEscapeDir.left),
      ArrowPathDef(cells: [(7, 4), (7, 5), (6, 5)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(1, 4)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(4, 7)], headDir: ArrowEscapeDir.right),
      ArrowPathDef(cells: [(6, 1), (6, 2)], headDir: ArrowEscapeDir.right),
    ],
  ),
  ArrowEscapeLevelDef(
    name: 'Dense',
    rows: 9,
    cols: 9,
    paths: [
      ArrowPathDef(cells: [(2, 2), (2, 3), (2, 4), (3, 4), (4, 4)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(6, 6), (6, 5), (6, 4), (5, 4)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(4, 2), (5, 2), (5, 3)], headDir: ArrowEscapeDir.right),
      ArrowPathDef(cells: [(3, 6), (4, 6)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(1, 6)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(7, 3)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(2, 7)], headDir: ArrowEscapeDir.right),
    ],
  ),
  ArrowEscapeLevelDef(
    name: 'Long snakes',
    rows: 10,
    cols: 10,
    paths: [
      ArrowPathDef(
        cells: [(5, 2), (5, 3), (5, 4), (5, 5), (4, 5), (3, 5), (3, 6), (3, 7)],
        headDir: ArrowEscapeDir.right,
      ),
      ArrowPathDef(
        cells: [(8, 7), (7, 7), (7, 6), (7, 5), (7, 4), (8, 4), (8, 3), (7, 3), (7, 2)],
        headDir: ArrowEscapeDir.left,
      ),
      ArrowPathDef(cells: [(2, 4), (2, 5), (2, 6)], headDir: ArrowEscapeDir.right),
      ArrowPathDef(cells: [(6, 8)], headDir: ArrowEscapeDir.right),
      ArrowPathDef(cells: [(1, 2), (2, 2)], headDir: ArrowEscapeDir.down),
    ],
  ),
  ArrowEscapeLevelDef(
    name: 'Crossfire',
    rows: 10,
    cols: 10,
    paths: [
      ArrowPathDef(cells: [(4, 3), (4, 4), (4, 5), (4, 6)], headDir: ArrowEscapeDir.right),
      ArrowPathDef(cells: [(5, 6), (5, 5), (5, 4), (5, 3)], headDir: ArrowEscapeDir.left),
      ArrowPathDef(cells: [(3, 4), (2, 4)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(6, 5), (7, 5)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(5, 1), (4, 1)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(4, 8), (5, 8)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(1, 7)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(8, 2)], headDir: ArrowEscapeDir.down),
    ],
  ),
  ArrowEscapeLevelDef(
    name: 'Fortress',
    rows: 10,
    cols: 10,
    paths: [
      ArrowPathDef(cells: [(5, 5), (5, 4), (5, 3), (6, 3), (7, 3)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(4, 5), (4, 6), (4, 7), (3, 7), (2, 7)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(5, 6), (6, 6), (7, 6)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(5, 2), (4, 2), (3, 2)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(8, 5)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(1, 5)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(5, 8)], headDir: ArrowEscapeDir.right),
      ArrowPathDef(cells: [(5, 1)], headDir: ArrowEscapeDir.up),
    ],
  ),
  ArrowEscapeLevelDef(
    name: 'Expert weave',
    rows: 11,
    cols: 11,
    paths: [
      ArrowPathDef(
        cells: [(8, 4), (8, 5), (7, 5), (7, 4), (7, 3), (6, 3), (5, 3)],
        headDir: ArrowEscapeDir.up,
      ),
      ArrowPathDef(
        cells: [(9, 8), (9, 9), (8, 9), (8, 8), (8, 7)],
        headDir: ArrowEscapeDir.left,
      ),
      ArrowPathDef(cells: [(2, 5), (3, 5), (3, 6)], headDir: ArrowEscapeDir.right),
      ArrowPathDef(cells: [(8, 6), (9, 6)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(5, 2), (4, 2), (3, 2)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(9, 4)], headDir: ArrowEscapeDir.right),
      ArrowPathDef(cells: [(1, 8)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(8, 2)], headDir: ArrowEscapeDir.right),
    ],
  ),
  ArrowEscapeLevelDef(
    name: 'Grand maze',
    rows: 12,
    cols: 12,
    paths: [
      ArrowPathDef(
        cells: [(10, 5), (10, 6), (10, 7), (9, 7), (8, 7), (8, 6), (8, 5), (7, 5)],
        headDir: ArrowEscapeDir.up,
      ),
      ArrowPathDef(
        cells: [(5, 8), (5, 7), (5, 6), (4, 6), (3, 6), (3, 7), (4, 7), (4, 8)],
        headDir: ArrowEscapeDir.right,
      ),
      ArrowPathDef(cells: [(9, 9), (9, 8), (8, 8)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(2, 4), (3, 4), (4, 4)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(10, 3)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(1, 9)], headDir: ArrowEscapeDir.up),
      ArrowPathDef(cells: [(6, 2), (7, 2), (8, 2)], headDir: ArrowEscapeDir.down),
      ArrowPathDef(cells: [(6, 9)], headDir: ArrowEscapeDir.right),
      ArrowPathDef(cells: [(2, 10)], headDir: ArrowEscapeDir.right),
    ],
  ),
];

/// Neon accent palette (cycles per arrow index).
Color kArrowEscapeNeonPalette(int arrowIndex) {
  const palette = <Color>[
    Color(0xFF00F5FF),
    Color(0xFFFF2D95),
    Color(0xFFFFB020),
    Color(0xFFB8FF2E),
    Color(0xFF8B5CFF),
    Color(0xFF20FFC8),
    Color(0xFFFF6B4A),
    Color(0xFF4DA3FF),
  ];
  return palette[arrowIndex % palette.length];
}
