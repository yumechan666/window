import 'dart:math';

// Port of game js/game/data.js

const int maxLevel = 75;

class ToolDef {
  final String label;
  final String short;
  final int unlock;
  final String kind; // "liquid" | "wipe"
  const ToolDef(this.label, this.short, this.unlock, this.kind);
}

const Map<String, ToolDef> tools = {
  'water': ToolDef('Water Bucket', 'Air', 1, 'liquid'),
  'sponge': ToolDef('Sponge', 'Spons', 1, 'wipe'),
  'glass_cleaner': ToolDef('Glass Cleaner', 'Kaca', 1, 'liquid'),
  'squeegee': ToolDef('Squeegee', 'Wiper', 1, 'wipe'),
  'cloth': ToolDef('Cloth', 'Kain', 6, 'wipe'),
  'degreaser': ToolDef('Degreaser', 'Minyak', 8, 'liquid'),
  'cleaning_spray': ToolDef('Spray Bottle', 'Spray', 11, 'liquid'),
  'small_brush': ToolDef('Small Brush', 'Brush', 11, 'wipe'),
  'descaler': ToolDef('Descaler', 'Kerak', 17, 'liquid'),
  'scrub_brush': ToolDef('Scrub Brush', 'Scrub', 17, 'wipe'),
  'mold_cleaner': ToolDef('Mold Cleaner', 'Jamur', 20, 'liquid'),
  'heavy_cleaner': ToolDef('Heavy Cleaner', 'Food', 26, 'liquid'),
  'paint_remover': ToolDef('Paint Remover', 'Cat', 31, 'liquid'),
  'scraper': ToolDef('Scraper', 'Kikis', 31, 'wipe'),
  'sticky_cleaner': ToolDef('Sticky Cleaner', 'Lengket', 36, 'liquid'),
  'heavy_duty': ToolDef('Heavy Duty', 'Heavy', 41, 'liquid'),
  'steam_cleaner': ToolDef('Steam Cleaner', 'Steam', 51, 'liquid'),
  'electric_scrubber': ToolDef('Electric Scrubber', 'Electric', 56, 'wipe'),
  'foam_sprayer': ToolDef('Foam Sprayer', 'Foam', 61, 'liquid'),
  'glass_polisher': ToolDef('Glass Polisher', 'Polish', 66, 'wipe'),
};

final List<String> toolOrder = tools.keys.toList();

class DirtDef {
  final String label;
  final List<String> recipe;
  final String hint;
  final List<String>? waitAfter;
  const DirtDef(this.label, this.recipe, this.hint, [this.waitAfter]);
}

const Map<String, DirtDef> dirt = {
  'dust': DirtDef('Debu', ['sponge'], 'Swipe dengan spons atau kain.'),
  'water_mark': DirtDef(
    'Bekas air',
    ['glass_cleaner', 'squeegee'],
    'Semprot kaca, lalu tarik dengan squeegee.',
    null,
  ),
  'fingerprint': DirtDef('Sidik jari', [
    'glass_cleaner',
    'cloth',
  ], 'Semprot, lalu lap dengan kain.'),
  'grease': DirtDef(
    'Minyak',
    ['degreaser', 'sponge'],
    'Degreaser perlu bekerja sebelum digosok.',
    ['degreaser'],
  ),
  'insect_splat': DirtDef(
    'Noda serangga',
    ['cleaning_spray', 'small_brush', 'sponge'],
    'Semprot, detail dengan small brush, lalu wipe.',
    ['cleaning_spray'],
  ),
  'bird_mess': DirtDef(
    'Kotoran burung',
    ['water', 'cleaning_spray', 'sponge'],
    'Basahi, lunakkan, lalu bersihkan.',
    ['cleaning_spray'],
  ),
  'scale': DirtDef(
    'Kerak',
    ['descaler', 'scrub_brush'],
    'Lunakkan kerak, lalu scrub.',
    ['descaler'],
  ),
  'mold': DirtDef('Lumut / jamur', [
    'mold_cleaner',
    'scrub_brush',
  ], 'Pakai mold cleaner, lalu scrub.'),
  'mud': DirtDef('Lumpur', ['water', 'sponge'], 'Basahi lumpur, lalu wipe.'),
  'food_stain': DirtDef('Noda makanan', [
    'heavy_cleaner',
    'sponge',
  ], 'Heavy cleaner, lalu lap.'),
  'paint': DirtDef(
    'Cat',
    ['paint_remover', 'scraper'],
    'Lunakkan cat, lalu kikis.',
    ['paint_remover'],
  ),
  'sticky': DirtDef('Noda lengket', [
    'sticky_cleaner',
    'scrub_brush',
    'cloth',
  ], 'Larutkan, scrub, lalu wipe.'),
  'heavy_stain': DirtDef(
    'Noda membandel',
    ['heavy_duty', 'scrub_brush', 'scrub_brush', 'cloth'],
    'Heavy duty, scrub berkali-kali, lalu finishing.',
    ['heavy_duty'],
  ),
};

class WindowTypeDef {
  final String key;
  final String label;
  final double aspect;
  final double scale;
  final String shape;
  const WindowTypeDef(
    this.key,
    this.label,
    this.aspect,
    this.scale,
    this.shape,
  );
}

const List<WindowTypeDef> windowTypes = [
  WindowTypeDef('small', 'Small Window', 0.8, 0.78, 'rect'),
  WindowTypeDef('standard', 'Standard Window', 0.72, 0.9, 'rect'),
  WindowTypeDef('large', 'Large Window', 0.82, 1, 'rect'),
  WindowTypeDef('tall', 'Tall Window', 0.55, 0.96, 'rect'),
  WindowTypeDef('wide', 'Wide Window', 1.35, 0.96, 'rect'),
  WindowTypeDef('round', 'Round Window', 1, 0.88, 'round'),
  WindowTypeDef('arched', 'Arched Window', 0.76, 0.94, 'arched'),
  WindowTypeDef('double', 'Double Window', 1.25, 0.98, 'double'),
  WindowTypeDef('sliding', 'Sliding Window', 1.3, 0.98, 'sliding'),
  WindowTypeDef('french', 'French Window', 0.9, 0.98, 'french'),
];

class WorldDef {
  final String key;
  final String label;
  final List<String> dirt;
  final String range;
  const WorldDef(this.key, this.label, this.dirt, this.range);
}

final List<WorldDef> worlds =
    [
          WorldDef('home', 'HOME', ['dust', 'water_mark'], ''),
          WorldDef('city', 'CITY', ['dust', 'water_mark', 'mud'], ''),
          WorldDef('cafe', 'CAFE', [
            'grease',
            'food_stain',
            'fingerprint',
            'dust',
          ], ''),
          WorldDef('school', 'SCHOOL', ['fingerprint', 'dust', 'paint'], ''),
          WorldDef('hospital', 'HOSPITAL', [
            'fingerprint',
            'water_mark',
            'sticky',
          ], ''),
          WorldDef('shopping', 'SHOPPING', [
            'fingerprint',
            'food_stain',
            'sticky',
          ], ''),
          WorldDef('beach', 'BEACH', ['water_mark', 'mold', 'mud'], ''),
          WorldDef('forest', 'FOREST', ['mold', 'mud', 'insect_splat'], ''),
          WorldDef('mountain', 'MOUNTAIN', ['mud', 'water_mark', 'scale'], ''),
          WorldDef('castle', 'CASTLE', [
            'dust',
            'mold',
            'scale',
            'heavy_stain',
          ], ''),
          WorldDef('snow_town', 'SNOW TOWN', [
            'water_mark',
            'scale',
            'mud',
          ], ''),
          WorldDef('amusement_park', 'AMUSEMENT PARK', [
            'food_stain',
            'fingerprint',
            'sticky',
          ], ''),
          WorldDef('train_station', 'TRAIN STATION', [
            'dust',
            'mud',
            'grease',
          ], ''),
          WorldDef('airport', 'AIRPORT', [
            'fingerprint',
            'dust',
            'heavy_stain',
          ], ''),
          WorldDef('sky_tower', 'SKY / SPACE', [
            'heavy_stain',
            'paint',
            'sticky',
            'scale',
          ], ''),
        ]
        .asMap()
        .map(
          (i, w) => MapEntry(
            i,
            WorldDef(w.key, w.label, w.dirt, '${i * 5 + 1}–${i * 5 + 5}'),
          ),
        )
        .values
        .toList();

class SkinDef {
  final String key;
  final String label;
  final int price;
  const SkinDef(this.key, this.label, this.price);
}

final List<SkinDef> skins = [
  ['cat', 'Cat', 0],
  ['bunny', 'Bunny', 150],
  ['puppy', 'Puppy', 150],
  ['panda', 'Panda', 150],
  ['fox', 'Fox', 200],
  ['bear', 'Bear', 200],
  ['frog', 'Frog', 200],
  ['hamster', 'Hamster', 200],
  ['mouse', 'Mouse', 250],
  ['raccoon', 'Raccoon', 250],
  ['koala', 'Koala', 250],
  ['penguin', 'Penguin', 250],
  ['duck', 'Duck', 300],
  ['chicken', 'Chicken', 300],
  ['pig', 'Pig', 300],
  ['cow', 'Cow', 300],
  ['deer', 'Deer', 350],
  ['tiger', 'Tiger', 350],
  ['lion', 'Lion', 350],
  ['monkey', 'Monkey', 350],
  ['red_panda', 'Red Panda', 400],
  ['otter', 'Otter', 400],
  ['capybara', 'Capybara', 400],
  ['unicorn', 'Unicorn', 500],
  ['wizard', 'Wizard', 500],
  ['robot', 'Robot', 500],
  ['alien', 'Alien', 500],
  ['ghost', 'Ghost', 600],
  ['witch', 'Witch', 600],
  ['astronaut', 'Astronaut', 600],
  ['strawberry', 'Strawberry', 400],
  ['axolotl', 'Axolotl', 450],
  ['dragon', 'Baby Dragon', 750],
].map((e) => SkinDef(e[0] as String, e[1] as String, e[2] as int)).toList();

const Map<String, int> dirtUnlocks = {
  'dust': 1,
  'water_mark': 1,
  'fingerprint': 6,
  'grease': 8,
  'insect_splat': 11,
  'bird_mess': 14,
  'scale': 17,
  'mold': 20,
  'mud': 23,
  'food_stain': 26,
  'paint': 31,
  'sticky': 36,
  'heavy_stain': 41,
};

class Difficulty {
  final String name;
  final int count;
  final double coverage;
  final int durability;
  const Difficulty(this.name, this.count, this.coverage, this.durability);
}

class SpotDef {
  final String id;
  final String type;
  final List<String> recipe;
  final double x;
  final double y;
  final double size;
  final double rotation;
  final int durability;
  SpotDef(
    this.id,
    this.type,
    this.recipe,
    this.x,
    this.y,
    this.size,
    this.rotation,
    this.durability,
  );
}

class LevelData {
  final int level;
  final WorldDef world;
  final List<SpotDef> spots;
  final int targetTime;
  final Difficulty difficulty;
  final WindowTypeDef windowType;
  LevelData(
    this.level,
    this.world,
    this.spots,
    this.targetTime,
    this.difficulty,
    this.windowType,
  );
}

int _seed(int seed) => seed & 0xFFFFFFFF;

int _randInt(double Function() next, int min, int max) =>
    (min + next() * (max - min + 1)).floor();

double Function() seededRandom(int seed) {
  int value = _seed(seed);
  return () {
    value = (value * 1664525 + 1013904223) & 0xFFFFFFFF;
    return (value >>> 0) / 4294967296;
  };
}

Difficulty difficultyFor(int level, double Function() random) {
  if (level <= 5) {
    return Difficulty('EASY', _randInt(random, 3, 6), 0.1 + random() * 0.15, 1);
  }
  if (level <= 10) {
    return Difficulty(
      'EASY+',
      _randInt(random, 6, 12),
      0.2 + random() * 0.2,
      1,
    );
  }
  if (level <= 20) {
    return Difficulty(
      'MEDIUM',
      _randInt(random, 12, 25),
      0.4 + random() * 0.25,
      1 + (level >= 17 ? 1 : 0),
    );
  }
  if (level <= 30) {
    return Difficulty(
      'HARD',
      _randInt(random, 20, 40),
      0.6 + random() * 0.2,
      2,
    );
  }
  if (level <= 50) {
    return Difficulty(
      'VERY HARD',
      _randInt(random, 30, 60),
      0.75 + random() * 0.2,
      level >= 41 ? 3 : 2,
    );
  }
  return Difficulty(
    'PRO',
    _randInt(random, 45, 70),
    0.85 + random() * 0.12,
    level >= 66 ? 4 : 3,
  );
}

List<String> recipeFor(String type, int level) {
  List<String> recipe = [...dirt[type]!.recipe];
  if (level >= 51) {
    recipe = recipe
        .map(
          (t) => ['water', 'glass_cleaner'].contains(t) ? 'steam_cleaner' : t,
        )
        .toList();
  }
  if (level >= 56) {
    recipe = recipe
        .map(
          (t) => ['sponge', 'scrub_brush', 'small_brush'].contains(t)
              ? 'electric_scrubber'
              : t,
        )
        .toList();
  }
  if (level >= 61) {
    recipe = recipe
        .map(
          (t) =>
              [
                'cleaning_spray',
                'degreaser',
                'mold_cleaner',
                'heavy_cleaner',
              ].contains(t)
              ? 'foam_sprayer'
              : t,
        )
        .toList();
  }
  if (level >= 66 && ['water_mark', 'bird_mess'].contains(type)) {
    recipe.add('glass_polisher');
  }
  if (level >= 66 && type == 'heavy_stain') {
    recipe[recipe.length - 1] = 'glass_polisher';
  }
  return recipe;
}

LevelData makeLevel(int level) {
  final safe = max(1, min(maxLevel, level));
  final random = seededRandom(safe * 92821 + 17);
  final world = worlds[((safe - 1) / 5).floor()];
  final difficulty = difficultyFor(safe, random);
  final available = dirt.keys
      .where((t) => (dirtUnlocks[t] ?? 999) <= safe)
      .toList();
  final worldAvailable = world.dirt
      .where((t) => (dirtUnlocks[t] ?? 999) <= safe)
      .toList();
  final windowType =
      windowTypes[(((safe - 1) / 3).floor() + (random() * 3).floor()) %
          windowTypes.length];
  final baseSize = sqrt(difficulty.coverage / difficulty.count) * 1.14;
  final spots = List.generate(difficulty.count, (index) {
    final pool = worldAvailable.isNotEmpty && random() < 0.62
        ? worldAvailable
        : available;
    final type = safe == 1 && index == 0
        ? 'dust'
        : pool[(random() * pool.length).floor()];
    double x = 0.06 + random() * 0.88;
    double y = 0.06 + random() * 0.88;
    if (windowType.shape == 'round') {
      int tries = 0;
      while (sqrt(pow(x - 0.5, 2) + pow(y - 0.5, 2)) > 0.43 && tries < 12) {
        x = 0.08 + random() * 0.84;
        y = 0.08 + random() * 0.84;
        tries += 1;
      }
    }
    return SpotDef(
      '$safe-$index',
      type,
      recipeFor(type, safe),
      x,
      y,
      max(0.09, min(0.34, baseSize * (0.72 + random() * 0.56))),
      (random() - 0.5) * 0.5,
      max(1, difficulty.durability + (random() > 0.78 ? 1 : 0)),
    );
  });
  final averageSteps =
      spots.fold(0, (s, sp) => s + sp.recipe.length) / spots.length;
  final targetTime = min(
    210,
    (18 +
            difficulty.count * 1.55 +
            averageSteps * 7 +
            difficulty.durability * 9)
        .round(),
  );
  return LevelData(safe, world, spots, targetTime, difficulty, windowType);
}

List<String> getUnlockedTools(int level) =>
    toolOrder.where((k) => tools[k]!.unlock <= level).toList();

int rewardForStars(int stars) => stars >= 3
    ? 120
    : stars == 2
    ? 90
    : stars == 1
    ? 60
    : 0;

String formatTime(double seconds) => '${max(0, seconds).toStringAsFixed(1)}s';
