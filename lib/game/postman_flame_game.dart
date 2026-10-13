import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart'
    show TextPainter, TextSpan, TextStyle, TextDirection;
import 'package:flutter/services.dart';

import 'postman_controller.dart';
import 'world_data.dart';

class _FrameData {
  const _FrameData(this.crop, this.anchor);
  final ui.Rect crop;
  final ui.Offset? anchor;
}

class _AtlasData {
  const _AtlasData({
    required this.imageName,
    required this.frames,
    required this.animations,
  });
  final String imageName;
  final Map<String, _FrameData> frames;
  final Map<String, List<String>> animations;
}

class PostmanFlameGame extends FlameGame {
  PostmanFlameGame(this.controller);

  final PostmanController controller;
  final Map<String, _AtlasData> _atlases = {};
  final Map<String, Future<void>> _skinLoads = {};
  double _elapsed = 0;
  double _lastSavedX = 260;

  static const _images = <String>[
    'bg_spring_forest.webp',
    'bg_rain_night.webp',
    'bg_coast_snow.webp',
    'bg_magic_castle.webp',
    'player_sheet-transparent.webp',
    'npc_luna_finn_sheet-transparent.webp',
    'npc_bruno_nia_sheet-transparent.webp',
    'npc_oliver_elia_sheet-transparent.webp',
    'npc_momo_mimi_sheet-transparent.webp',
    'landmark_atlas-transparent.webp',
    'prop_atlas-transparent.webp',
    'puzzle_atlas-transparent.webp',
    'ui_atlas-transparent.webp',
    'ground_strip-transparent.webp',
    'delivery_effect_atlas-transparent.webp',
  ];

  static const _atlasesToLoad = <(String, String)>[
    ('player_sheet-transparent.frames.json', 'player_sheet-transparent.webp'),
    (
      'npc_luna_finn_sheet-transparent.frames.json',
      'npc_luna_finn_sheet-transparent.webp',
    ),
    (
      'npc_bruno_nia_sheet-transparent.frames.json',
      'npc_bruno_nia_sheet-transparent.webp',
    ),
    (
      'npc_oliver_elia_sheet-transparent.frames.json',
      'npc_oliver_elia_sheet-transparent.webp',
    ),
    (
      'npc_momo_mimi_sheet-transparent.frames.json',
      'npc_momo_mimi_sheet-transparent.webp',
    ),
    (
      'landmark_atlas-transparent.frames.json',
      'landmark_atlas-transparent.webp',
    ),
    ('prop_atlas-transparent.frames.json', 'prop_atlas-transparent.webp'),
    ('puzzle_atlas-transparent.frames.json', 'puzzle_atlas-transparent.webp'),
    ('ui_atlas-transparent.frames.json', 'ui_atlas-transparent.webp'),
    ('ground_strip-transparent.frames.json', 'ground_strip-transparent.webp'),
    (
      'delivery_effect_atlas-transparent.frames.json',
      'delivery_effect_atlas-transparent.webp',
    ),
  ];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await Future.wait(_images.map(images.load));
    await Future.wait(_atlasesToLoad.map(_loadAtlas));
  }

  Future<void> loadSkin(String skin) async {
    if (!playerSkins.any((entry) => entry.$1 == skin)) return;
    final imageName = 'player_skin_$skin-transparent.webp';
    if (_atlases.containsKey(imageName)) return;
    try {
      await _skinLoads.putIfAbsent(imageName, () async {
        await images.load(imageName);
        await _loadAtlas((
          'player_skin_$skin-transparent.frames.json',
          imageName,
        ));
      });
    } catch (_) {
      _skinLoads.remove(imageName);
    }
  }

  Future<void> _loadAtlas((String, String) entry) async {
    final raw = await rootBundle.loadString('assets/json/${entry.$1}');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final frames = <String, _FrameData>{};
    for (final value in data['frames'] as List<dynamic>? ?? const []) {
      final frame = Map<String, dynamic>.from(value as Map);
      final content = Map<String, dynamic>.from(
        frame['content'] as Map? ?? frame['source'] as Map,
      );
      final anchorValue = frame['anchor'];
      ui.Offset? anchor;
      if (anchorValue is Map) {
        anchor = ui.Offset(
          (anchorValue['x'] as num).toDouble(),
          (anchorValue['y'] as num).toDouble(),
        );
      }
      frames[frame['name'] as String] = _FrameData(
        ui.Rect.fromLTWH(
          (content['x'] as num).toDouble(),
          (content['y'] as num).toDouble(),
          (content['w'] as num).toDouble(),
          (content['h'] as num).toDouble(),
        ),
        anchor,
      );
    }
    final animations = <String, List<String>>{};
    for (final value in data['animations'] as List<dynamic>? ?? const []) {
      final animation = Map<String, dynamic>.from(value as Map);
      animations[animation['name'] as String] =
          (animation['frames'] as List<dynamic>)
              .map(
                (frame) =>
                    frame is Map ? frame['name'] as String : frame.toString(),
              )
              .toList();
    }
    _atlases[entry.$2] = _AtlasData(
      imageName: entry.$2,
      frames: frames,
      animations: animations,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    controller.updateGame(dt.clamp(0, .05));
    if ((controller.playerX - _lastSavedX).abs() >= 160) {
      _lastSavedX = controller.playerX;
      controller.save['currentX'] = controller.playerX.round();
      unawaited(controller.persist());
    }
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final width = size.x;
    final height = size.y;
    if (width <= 0 || height <= 0) return;
    final world = controller.world;
    final groundY = (height * .76).clamp(height - 150, height - 74).toDouble();
    canvas.save();
    canvas.clipRect(ui.Rect.fromLTWH(0, 0, width, height));
    _drawBackdrop(canvas, width, height, world);
    _drawWeather(canvas, width, height, world.weather);
    _drawGround(canvas, width, height, groundY, world.palette[2]);
    _drawLandmarksAndProps(canvas, width, height, groundY, world);
    _drawFriends(canvas, width, height, groundY, world);
    _drawPlayer(canvas, width, height, groundY);
    _drawVignette(canvas, width, height, world.palette[4]);
    canvas.restore();
  }

  void _drawBackdrop(
    ui.Canvas canvas,
    double width,
    double height,
    WorldData world,
  ) {
    final image = images.fromCache(world.backdrop);
    final tileWidth = image.width * (height / image.height);
    if (tileWidth <= 0) return;
    final offset = -((controller.cameraX * .08) % tileWidth);
    canvas.drawColor(ui.Color(world.palette[0]), ui.BlendMode.src);
    for (var x = offset - tileWidth; x < width + tileWidth; x += tileWidth) {
      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        ui.Rect.fromLTWH(x, 0, tileWidth, height),
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
    }
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, width, height),
      ui.Paint()..color = ui.Color(world.palette[1]).withValues(alpha: .12),
    );
  }

  void _drawWeather(
    ui.Canvas canvas,
    double width,
    double height,
    String weather,
  ) {
    final count = controller.reducedMotion ? 10 : 24;
    for (var i = 0; i < count; i++) {
      final seed = i * 977 + controller.worldId * 131;
      final speed = weather == 'rain'
          ? 190.0
          : weather == 'snow'
          ? 16.0
          : 10 + seed % 9;
      final x = ((seed * 1.71 + _elapsed * speed) % (width + 80)) - 40;
      final y = ((seed * .83 + _elapsed * speed * .62) % (height + 60)) - 30;
      final sway = math.sin(_elapsed * 1.5 + i) * 10;
      if (weather == 'rain') {
        canvas.drawLine(
          ui.Offset(x, y),
          ui.Offset(x - 8, y + 20),
          ui.Paint()
            ..color = const ui.Color(0x88d2ebee)
            ..strokeWidth = 1.3,
        );
      } else if (weather == 'snow' ||
          weather == 'starfall' ||
          weather == 'postal_sparkle' ||
          weather == 'firefly' ||
          weather == 'rune') {
        final color = weather == 'snow'
            ? const ui.Color(0xccfffff5)
            : weather == 'firefly'
            ? const ui.Color(0xb8efe06c)
            : const ui.Color(0xb8ffe299);
        canvas.drawCircle(
          ui.Offset(x + sway, y),
          weather == 'snow' ? 2.5 + i % 3 : 2.0,
          ui.Paint()..color = color,
        );
      } else if (weather == 'bubble' || weather == 'cloud_mote') {
        canvas.drawCircle(
          ui.Offset(x + sway, height - y),
          2 + i % 4,
          ui.Paint()
            ..color = const ui.Color(0x77efffff)
            ..style = ui.PaintingStyle.stroke,
        );
      } else {
        final color = weather == 'leaf'
            ? const ui.Color(0x88a65b36)
            : weather == 'petal'
            ? const ui.Color(0x88ef9db3)
            : const ui.Color(0x77f1da8d);
        canvas.save();
        canvas.translate(x + sway, y);
        canvas.rotate(_elapsed * .8 + i);
        canvas.drawOval(
          ui.Rect.fromCenter(center: ui.Offset.zero, width: 8, height: 4),
          ui.Paint()..color = color,
        );
        canvas.restore();
      }
    }
  }

  void _drawGround(
    ui.Canvas canvas,
    double width,
    double height,
    double groundY,
    int color,
  ) {
    final image = images.fromCache('ground_strip-transparent.webp');
    final frame =
        _atlases['ground_strip-transparent.webp']?.frames.values.first;
    if (frame == null) return;
    final scale = (height / 880).clamp(.48, .78);
    final tileWidth = frame.crop.width * scale;
    final source = frame.crop;
    final surfaceY = 82 * scale;
    final drawY = groundY - surfaceY;
    final offset = -((controller.cameraX * .98) % tileWidth);
    for (var x = offset - tileWidth; x < width + tileWidth; x += tileWidth) {
      canvas.drawImageRect(
        image,
        source,
        ui.Rect.fromLTWH(x, drawY, tileWidth, source.height * scale),
        ui.Paint()..filterQuality = ui.FilterQuality.medium,
      );
    }
    canvas.drawRect(
      ui.Rect.fromLTWH(
        0,
        drawY + source.height * scale - 2,
        width,
        height - drawY,
      ),
      ui.Paint()..color = ui.Color(color),
    );
  }

  double _screenX(double x, double width) => x - controller.cameraX + width / 2;

  void _drawLandmarksAndProps(
    ui.Canvas canvas,
    double width,
    double height,
    double groundY,
    WorldData world,
  ) {
    final scaleFactor = (height / 720).clamp(.75, 1.08);
    for (final landmark in world.landmarks) {
      final x = _screenX(landmark.x, width);
      if (x < -260 || x > width + 260) continue;
      _drawAnchored(
        canvas,
        'landmark_atlas-transparent.webp',
        landmark.frame,
        ui.Offset(
          x,
          groundY +
              9 +
              (controller.reducedMotion
                  ? 0
                  : math.sin(_elapsed * .8 + landmark.x) * 1.5),
        ),
        landmark.scale * scaleFactor,
      );
    }
    for (var i = 0; i < world.props.length; i++) {
      if (controller.heldPropIndex == i) continue;
      final prop = world.props[i];
      final x = _screenX(
        controller.objectPositions['${world.id}-$i'] ?? prop.x,
        width,
      );
      if (x < -100 || x > width + 100) continue;
      _drawAnchored(
        canvas,
        'prop_atlas-transparent.webp',
        prop.frame,
        ui.Offset(x, groundY + 3),
        .22 * (height / 700).clamp(.78, 1.08),
      );
    }
  }

  void _drawFriends(
    ui.Canvas canvas,
    double width,
    double height,
    double groundY,
    WorldData world,
  ) {
    final scale = (height / 1600).clamp(.32, .5);
    for (var index = 0; index < friends.length; index++) {
      final friend = friends[index];
      final worldX = world.npcPositions[friend.id]!;
      final screenX = _screenX(worldX, width);
      if (screenX < -130 || screenX > width + 130) continue;
      final isReceiving =
          controller.activeFriendId == friend.id &&
          controller.screen == GameScreen.delivery;
      final animationName = isReceiving
          ? '${friend.id}_receive'
          : '${friend.id}_idle';
      final frame = _animatedFrame(
        friend.sheet,
        animationName,
        330 + index * 17,
        index * 173,
      );
      if (frame != null) {
        _drawFrame(
          canvas,
          friend.sheet,
          frame,
          ui.Offset(screenX, groundY + 2),
          scale,
          controller.playerX > worldX,
        );
      }
      _drawName(
        canvas,
        '${friend.name}${controller.delivered.contains(friend.id) ? '  ✓' : ''}',
        screenX,
        groundY - (height * .25).clamp(110, 166),
        world.palette[3],
      );
      final closest = controller.nearestFriend;
      if (closest?.$1.id == friend.id && closest!.$2 < 125) {
        final pulse = 1 + math.sin(_elapsed * 6) * .16;
        canvas.drawCircle(
          ui.Offset(screenX, groundY - (height * .31).clamp(140, 198)),
          6 * pulse,
          ui.Paint()..color = const ui.Color(0xfffff3c4),
        );
      }
    }
  }

  void _drawPlayer(
    ui.Canvas canvas,
    double width,
    double height,
    double groundY,
  ) {
    final skin = controller.selectedSkin;
    final imageName = 'player_skin_$skin-transparent.webp';
    final atlas = _atlases.containsKey(imageName)
        ? imageName
        : 'player_sheet-transparent.webp';
    final animation = controller.playerY > 1 || controller.isMoving
        ? 'walk'
        : 'idle';
    final frame = _animatedFrame(
      atlas,
      animation,
      controller.isMoving ? 95 : 380,
    );
    if (frame != null) {
      final x = _screenX(controller.playerX, width);
      _drawFrame(
        canvas,
        atlas,
        frame,
        ui.Offset(x, groundY + 3 - controller.playerY),
        (height / 1600).clamp(.32, .5) * .98,
        controller.direction < 0,
      );
    }
    final heldIndex = controller.heldPropIndex;
    if (heldIndex != null &&
        heldIndex >= 0 &&
        heldIndex < controller.world.props.length) {
      final prop = controller.world.props[heldIndex];
      final x =
          _screenX(controller.playerX, width) +
          controller.direction * (height * .055).clamp(24, 38);
      final y = groundY - (height * .11).clamp(48, 74) - controller.playerY;
      _drawAnchored(
        canvas,
        'prop_atlas-transparent.webp',
        prop.frame,
        ui.Offset(x, y),
        .1 * (height / 700).clamp(.8, 1.1),
      );
    }
  }

  String? _animatedFrame(
    String imageName,
    String animationName,
    int frameDurationMs, [
    int offsetMs = 0,
  ]) {
    final atlas = _atlases[imageName];
    if (atlas == null) return null;
    final names = atlas.animations[animationName];
    if (names == null || names.isEmpty) {
      return atlas.frames.isEmpty ? null : atlas.frames.keys.first;
    }
    final index =
        ((_elapsed * 1000 + offsetMs) / frameDurationMs).floor() % names.length;
    return names[index];
  }

  void _drawAnchored(
    ui.Canvas canvas,
    String imageName,
    String frameName,
    ui.Offset bottom,
    double scale,
  ) {
    final frame = _atlases[imageName]?.frames[frameName];
    if (frame == null) return;
    _drawFrame(canvas, imageName, frameName, bottom, scale);
  }

  void _drawFrame(
    ui.Canvas canvas,
    String imageName,
    String frameName,
    ui.Offset bottom,
    double scale, [
    bool mirror = false,
  ]) {
    final atlas = _atlases[imageName];
    final frame = atlas?.frames[frameName];
    if (atlas == null || frame == null) return;
    final image = images.fromCache(imageName);
    final crop = frame.crop;
    final anchor = frame.anchor ?? ui.Offset(crop.center.dx, crop.bottom);
    final left = -(anchor.dx - crop.left) * scale;
    final top = -(anchor.dy - crop.top) * scale;
    final destination = ui.Rect.fromLTWH(
      left,
      top,
      crop.width * scale,
      crop.height * scale,
    );
    canvas.save();
    canvas.translate(bottom.dx, bottom.dy);
    if (mirror) canvas.scale(-1, 1);
    canvas.drawImageRect(
      image,
      crop,
      destination,
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    canvas.restore();
  }

  void _drawName(
    ui.Canvas canvas,
    String text,
    double x,
    double y,
    int accent,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xff523f34),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width + 18;
    final rect = ui.Rect.fromLTWH(x - width / 2, y - 15, width, 23);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(12)),
      ui.Paint()..color = const ui.Color(0xeafff9e4),
    );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(12)),
      ui.Paint()
        ..color = ui.Color(accent)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    painter.paint(canvas, ui.Offset(x - painter.width / 2, y - 11));
  }

  void _drawVignette(ui.Canvas canvas, double width, double height, int ink) {
    final paint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(0, height * .68),
        ui.Offset(0, height),
        [const ui.Color(0x00000000), ui.Color(ink).withValues(alpha: .2)],
      );
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, width, height), paint);
  }
}
