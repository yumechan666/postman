import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'postman_audio.dart';
import 'postman_controller.dart';
import 'postman_flame_game.dart';
import 'l10n.dart';
import 'world_data.dart';

const _ink = Color(0xff574235);
const _leaf = Color(0xff547649);
const _paper = Color(0xfffff8e9);
const _paperDeep = Color(0xfff1e3c6);

class _SkinImageData {
  const _SkinImageData(this.image, this.source);
  final ui.Image image;
  final ui.Rect source;
}

class SkinPreview extends StatelessWidget {
  const SkinPreview({required this.skin, super.key});

  final String skin;

  static final Map<String, Future<_SkinImageData>> _cache = {};

  Future<_SkinImageData> _load() => _cache.putIfAbsent(skin, () async {
    final imageName = 'player_skin_$skin-transparent.webp';
    final metadataName = 'player_skin_$skin-transparent.frames.json';
    final metadata =
        jsonDecode(await rootBundle.loadString('assets/json/$metadataName'))
            as Map<String, dynamic>;
    final idle = (metadata['animations'] as List<dynamic>)
        .cast<Map>()
        .firstWhere((animation) => animation['name'] == 'idle');
    final first = (idle['frames'] as List<dynamic>).first as Map;
    final frame = (metadata['frames'] as List<dynamic>).cast<Map>().firstWhere(
      (entry) => entry['name'] == first['name'],
    );
    final crop = Map<String, dynamic>.from(
      frame['content'] as Map? ?? frame['source'] as Map,
    );
    final data = await rootBundle.load('assets/images/$imageName');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    return _SkinImageData(
      image,
      ui.Rect.fromLTWH(
        (crop['x'] as num).toDouble(),
        (crop['y'] as num).toDouble(),
        (crop['w'] as num).toDouble(),
        (crop['h'] as num).toDouble(),
      ),
    );
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<_SkinImageData>(
    future: _load(),
    builder: (context, snapshot) {
      final data = snapshot.data;
      if (data == null) return const Icon(Icons.person, color: _leaf, size: 34);
      return CustomPaint(
        painter: _SkinPreviewPainter(data),
        child: const SizedBox.expand(),
      );
    },
  );
}

class _SkinPreviewPainter extends CustomPainter {
  const _SkinPreviewPainter(this.data);
  final _SkinImageData data;

  @override
  void paint(Canvas canvas, Size size) {
    final source = data.source;
    final scale = (size.width / source.width)
        .clamp(0, size.height / source.height)
        .toDouble();
    final width = source.width * scale;
    final height = source.height * scale;
    final destination = ui.Rect.fromLTWH(
      (size.width - width) / 2,
      (size.height - height) / 2,
      width,
      height,
    );
    canvas.drawImageRect(
      data.image,
      source,
      destination,
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _SkinPreviewPainter oldDelegate) =>
      oldDelegate.data != data;
}

class PostmanApp extends StatelessWidget {
  const PostmanApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Little Forest Postman',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _leaf, surface: _paper),
      scaffoldBackgroundColor: _paper,
      fontFamily: 'Nunito',
    ),
    home: const PostmanHomePage(),
  );
}

class PostmanHomePage extends StatefulWidget {
  const PostmanHomePage({super.key});

  @override
  State<PostmanHomePage> createState() => _PostmanHomePageState();
}

class _PostmanHomePageState extends State<PostmanHomePage>
    with WidgetsBindingObserver {
  late final PostmanAudio _audio;
  late final PostmanController _controller;
  late final PostmanFlameGame _game;
  final FocusNode _focusNode = FocusNode();
  bool _saveLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audio = PostmanAudio();
    _controller = PostmanController(audio: _audio);
    _game = PostmanFlameGame(_controller);
    _controller.addListener(_syncAudio);
    _syncAudio();
    unawaited(
      _controller.load().then((_) {
        if (!mounted) return;
        _saveLoaded = true;
        unawaited(_game.loadSkin(_controller.selectedSkin));
      }),
    );
  }

  void _syncAudio() {
    final base = _controller.settings;
    final settings = _controller.muted
        ? {...base, 'music': false, 'ambience': false, 'sfx': false}
        : base;
    _audio.synchronize(
      settings: settings,
      world: _controller.world,
      inGame: _controller.screen == GameScreen.play,
    );
    if (_saveLoaded) unawaited(_game.loadSkin(_controller.selectedSkin));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Persist progress whenever the app is backgrounded or closed abruptly.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      if (_saveLoaded) unawaited(_controller.saveNow());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _controller.removeListener(_syncAudio);
    _controller.dispose();
    unawaited(_audio.dispose());
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
    final isUp = event is KeyUpEvent;
    if (event is KeyDownEvent) unawaited(_audio.unlock());
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA) {
      if (isDown || isUp) _controller.setMove(-1, isDown);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD) {
      if (isDown || isUp) _controller.setMove(1, isDown);
      return KeyEventResult.handled;
    }
    if (isDown &&
        (event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.keyW)) {
      _controller.jump();
      return KeyEventResult.handled;
    }
    if (isDown &&
        (event.logicalKey == LogicalKeyboardKey.keyE ||
            event.logicalKey == LogicalKeyboardKey.enter)) {
      _controller.interact();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _focusNode,
    autofocus: true,
    onKeyEvent: _onKey,
    child: Listener(
      onPointerDown: (_) => unawaited(_audio.unlock()),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            GameWidget<PostmanFlameGame>(game: _game),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => _buildLayer(context),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildLayer(BuildContext context) {
    return switch (_controller.screen) {
      GameScreen.play => _buildHud(context),
      GameScreen.menu => _buildMenu(context),
      GameScreen.routeSetup => _buildRouteSetup(context),
      GameScreen.map => _buildMap(context),
      GameScreen.friends => _buildFriends(context),
      GameScreen.letters => _buildLetters(context),
      GameScreen.wardrobe => _buildWardrobe(context),
      GameScreen.settings => _buildSettings(context),
      GameScreen.dialogue => _buildDialogue(context),
      GameScreen.puzzle => _buildPuzzle(context),
      GameScreen.delivery => _buildDelivery(context),
      GameScreen.complete => _buildComplete(context),
      GameScreen.ending => _buildEnding(context),
      GameScreen.confirm => _buildConfirm(context),
      GameScreen.tutorial => _buildTutorial(context),
    };
  }

  Widget _buildMenu(BuildContext context) {
    String t(String key) => AppLocalizations.tr(_controller.language, key);
    return _overlay(
      child: _paperPanel(
        maxWidth: 460,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mark_email_unread_rounded,
                size: 50,
                color: _leaf,
              ),
              const SizedBox(height: 10),
              Text(
                t('gameTitle1'),
                style: _titleStyle(32),
                textAlign: TextAlign.center,
              ),
              Text(
                t('gameTitle2'),
                style: _titleStyle(38, color: _leaf),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                t('subtitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: _ink, fontSize: 13),
              ),
              const SizedBox(height: 22),
              _buildMenuOptions(context),
              const SizedBox(height: 22),
              _button(
                '${t('continue')} · World ${_controller.worldId}',
                _continueJourney,
                primary: true,
                icon: Icons.play_arrow_rounded,
              ),
              const SizedBox(height: 8),
              _button(
                t('beforeRoute'),
                () => _controller.openRouteSetup(),
                icon: Icons.tune_rounded,
              ),
              const SizedBox(height: 8),
              _button(
                t('howToPlay'),
                () => _controller.openTutorial(),
                icon: Icons.help_outline_rounded,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _miniIcon(t('worldMap'), Icons.map_outlined, _controller.openMap),
                  _miniIcon(
                    t('forestFriends'),
                    Icons.people_outline_rounded,
                    _controller.openFriends,
                  ),
                  _miniIcon(
                    t('letters'),
                    Icons.menu_book_rounded,
                    _controller.openLetters,
                  ),
                  _miniIcon(
                    t('wardrobe'),
                    Icons.checkroom_rounded,
                    _controller.openWardrobe,
                  ),
                  _miniIcon(
                    t('settings'),
                    Icons.settings_outlined,
                    _controller.openSettings,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '✦ ${_controller.coins} ${t('forestCoins')}   ·   ${_controller.letters.length}/200 ${t('lettersCollected')}',
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    unawaited(_audio.playSfx('click'));
                    _controller.requestReset();
                  },
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: Text(t('resetProgress')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xffa34d42),
                    side: const BorderSide(color: Color(0xffd9b8a5)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOptions(BuildContext context) {
    String t(String key) => AppLocalizations.tr(_controller.language, key);
    final langOptions = AppLocalizations.languages
        .map((code) => (code, AppLocalizations.label(code), ''))
        .toList();
    final modeOptions = <(String, String, String)>[
      ('story', t('modeStory'), ''),
      ('relaxed', t('modeRelaxed'), ''),
      ('challenge', t('modeChallenge'), ''),
    ];
    final selectedMode = modeOptions.firstWhere(
      (option) => option.$1 == _controller.playMode,
      orElse: () => modeOptions.first,
    );
    return Column(
      children: [
        _optionGroup(
          t('language'),
          langOptions,
          _controller.language,
          (value) => unawaited(_controller.selectLanguage(value)),
        ),
        const SizedBox(height: 12),
        _optionGroup(
          t('playMode'),
          modeOptions,
          _controller.playMode,
          (value) => unawaited(_controller.selectPlayMode(value)),
        ),
        const SizedBox(height: 6),
        Text(
          selectedMode.$3,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _ink, fontSize: 12),
        ),
      ],
    );
  }

  Widget _optionGroup(
    String title,
    List<(String, String, String)> options,
    String selected,
    ValueChanged<String> onSelect,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(color: _leaf, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options
            .map(
              (option) => _choiceChip(
                option.$2,
                option.$3,
                selected == option.$1,
                () => onSelect(option.$1),
              ),
            )
            .toList(),
      ),
    ],
  );

  Widget _choiceChip(
    String label,
    String description,
    bool selected,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: () {
      unawaited(_audio.playSfx('click'));
      onTap();
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xffe3edd8)
            : const Color(0xfff8efd9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? _leaf : const Color(0xffe5d7ba),
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w900),
          ),
          if (description.isNotEmpty)
            Text(
              description,
              style: const TextStyle(color: _ink, fontSize: 10),
            ),
        ],
      ),
    ),
  );

  Future<void> _continueJourney() async =>
      _controller.startWorld(_controller.worldId);

  Widget _buildRouteSetup(BuildContext context) {
    String t(String key) => AppLocalizations.tr(_controller.language, key);
    return _panelOverlay(
      title: t('routeSetupTitle'),
      subtitle: t('routeSetupSubtitle'),
      onBack: _controller.backToMenu,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              t('skinTitle'),
              style: const TextStyle(
                color: _leaf,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: playerSkins.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final skin = playerSkins[index];
            final selected = _controller.selectedSkin == skin.$1;
            return InkWell(
              onTap: () => _controller.selectSkin(skin.$1),
              borderRadius: BorderRadius.circular(13),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xffe3edd8)
                      : const Color(0xfff8efd9),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: selected ? _leaf : Colors.white,
                    width: selected ? 2 : 1,
                  ),
                ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 46,
                          height: 46,
                          child: SkinPreview(skin: skin.$1),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                skin.$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _controller.isSkinOwned(skin.$1)
                                    ? (_controller.selectedSkin == skin.$1
                                        ? 'Dipakai'
                                        : 'Dimiliki')
                                    : '✦ ${_controller.skinCost(skin.$1)}',
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle, color: _leaf, size: 17),
                      ],
                    ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          t('quickSettings'),
          style: const TextStyle(color: _leaf, fontWeight: FontWeight.w900),
        ),
        _setting(t('music'), t('musicDesc'), 'music'),
        _setting(t('ambience'), t('ambienceDesc'), 'ambience'),
        _setting(t('sfx'), t('sfxDesc'), 'sfx'),
        _setting(
          t('reducedMotion'),
          t('reducedMotionDesc'),
          'reducedMotion',
        ),
        const SizedBox(height: 10),
        _button(
          '${t('startRoute')} ${playerSkins.firstWhere((skin) => skin.$1 == _controller.selectedSkin).$2}',
          () => _controller.startWorld(_controller.worldId),
          primary: true,
          icon: Icons.route_rounded,
        ),
      ],
    ),
    );
  }

  Widget _buildHud(BuildContext context) {
    String t(String key) => AppLocalizations.tr(_controller.language, key);
    final world = _controller.world;
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: 62,
            right: 12,
            child: Column(
              children: [
                _circleButton(
                  _controller.muted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  _controller.muted ? t('unmuteSound') : t('muteSound'),
                  _controller.toggleMute,
                ),
                const SizedBox(height: 8),
                _circleButton(
                  Icons.help_outline_rounded,
                  t('howToPlay'),
                  () => _controller.openTutorial(fromGame: true),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _circleButton(
                  Icons.home_rounded,
                  'Main menu',
                  _controller.openMenu,
                ),
                const SizedBox(width: 8),
                _circleButton(
                  Icons.map_outlined,
                  'World map',
                  () => _controller.openMap(fromGame: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _badge(
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'WORLD ${world.id}',
                          style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            color: _leaf,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          world.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _badge(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 14,
                        color: Color(0xffdcad43),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${_controller.coins}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _badge(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mail_rounded, size: 16, color: _leaf),
                      const SizedBox(width: 5),
                      Text(
                        '${_controller.deliveredCount}/8',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_controller.nearbyPrompt != null)
            Positioned(
              bottom: 102,
              left: 0,
              right: 0,
              child: Center(
                child: _badge(
                  Text(
                    _controller.nearbyPrompt!,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _holdButton('‹', 'Walk left', -1),
                const SizedBox(width: 8),
                _holdButton('›', 'Walk right', 1),
                const Spacer(),
                _controlButton(
                  Icons.arrow_upward_rounded,
                  'Jump',
                  _controller.jump,
                ),
                const SizedBox(width: 8),
                _controlButton(
                  Icons.auto_awesome_rounded,
                  _controller.nearbyPrompt == null ? 'Interact' : 'Talk',
                  _controller.interact,
                  wide: true,
                ),
              ],
            ),
          ),
          if (_controller.toast != null)
            Positioned(
              left: 18,
              right: 18,
              bottom: 92,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _badge(
                    Text(
                      _controller.toast!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    String t(String key) => AppLocalizations.tr(_controller.language, key);
    final records = _controller.worldRecords;
    final stars = records.values.whereType<Map>().fold<int>(
      0,
      (sum, item) => sum + ((item['stars'] as num?)?.toInt() ?? 0),
    );
    return _panelOverlay(
      title: t('worldMap'),
      subtitle: _controller.language == 'id'
          ? '$stars/75 bintang rute · ${_controller.letters.length}/200 surat'
          : '$stars/75 route stars · ${_controller.letters.length}/200 letters',
      onBack: _controller.backFromMap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 25,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: width > 620 ? 3 : 2,
              mainAxisExtent: 76,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final id = index + 1;
              final world = worldFor(id, _controller.language);
              final record = records['$id'] as Map<String, dynamic>?;
              final unlocked = id <= _controller.unlockedWorld;
              final earned = (record?['stars'] as num?)?.toInt() ?? 0;
              return InkWell(
                onTap: unlocked ? () => _controller.selectWorld(id) : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: unlocked
                        ? Color(world.palette[0]).withValues(alpha: .85)
                        : const Color(0xffe6ddc9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: unlocked ? Color(world.palette[3]) : Colors.white,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: unlocked
                            ? Color(world.palette[3])
                            : const Color(0xffc9c0ae),
                        foregroundColor: Colors.white,
                        child: Text(
                          unlocked ? '$id' : '•',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              world.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _controller.language == 'id'
                                  ? '${(record?['delivered'] as List<dynamic>?)?.length ?? 0}/8 terkirim'
                                  : '${(record?['delivered'] as List<dynamic>?)?.length ?? 0}/8 delivered',
                              style: const TextStyle(color: _ink, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '★' * earned + '☆' * (3 - earned),
                        style: const TextStyle(
                          color: Color(0xffd69f31),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFriends(BuildContext context) {
    String t(String key) => AppLocalizations.tr(_controller.language, key);
    final lang = _controller.language;
    return _panelOverlay(
    title: t('forestFriends'),
    subtitle: t('friendsSubtitle'),
    onBack: _controller.backToMenu,
    child: Column(
      children: friends
          .map(
            (friend) => Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(friend.color).withValues(alpha: .12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Color(friend.color),
                    foregroundColor: Colors.white,
                    child: Text(
                      friend.name[0],
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${friend.name} the ${friendSpecies(friend, lang)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                          ),
                        ),
                        Text(
                          friendPersonality(friend, lang),
                          style: const TextStyle(
                            color: _leaf,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _controller.biography(friend),
                          style: const TextStyle(color: _ink, height: 1.25),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );
  }

  Widget _buildLetters(BuildContext context) {
    String t(String key) => AppLocalizations.tr(_controller.language, key);
    final items = _controller.letters.reversed.toList();
    return _panelOverlay(
      title: t('letters'),
      subtitle: _controller.language == 'id'
          ? '${items.length} momen cerita berhasil diantar'
          : '${items.length} story moments safely delivered',
      onBack: _controller.backToMenu,
      child: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                t('lettersEmpty'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: _ink),
              ),
            )
          : Column(
              children: items
                  .map(
                    (letter) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xfff9efd9),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: _leaf,
                            foregroundColor: Colors.white,
                            child: Text('${letter['world'] ?? 1}'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${letter['title'] ?? 'A forest letter'}',
                                  style: const TextStyle(
                                    color: _ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${letter['letter'] ?? ''}',
                                  style: const TextStyle(color: _ink),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${letter['story'] ?? ''}',
                                  style: const TextStyle(
                                    color: _leaf,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildWardrobe(BuildContext context) {
    String t(String key) => AppLocalizations.tr(_controller.language, key);
    return _panelOverlay(
    title: t('wardrobe'),
    subtitle: t('wardrobeSubtitle'),
    onBack: _controller.backToMenu,
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: playerSkins.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.35,
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
      ),
      itemBuilder: (context, index) {
        final skin = playerSkins[index];
        final selected = _controller.selectedSkin == skin.$1;
        return InkWell(
          onTap: () => _controller.selectSkin(skin.$1),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xffe3edd8)
                  : const Color(0xfff8efd9),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: selected ? _leaf : Colors.white,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: SkinPreview(skin: skin.$1),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skin.$2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        skin.$3,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _ink, fontSize: 10),
                      ),
                      Text(
                        _controller.isSkinOwned(skin.$1)
                            ? (_controller.selectedSkin == skin.$1
                                ? 'Dipakai'
                                : 'Dimiliki')
                            : '✦ ${_controller.skinCost(skin.$1)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _leaf,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: _leaf, size: 18),
              ],
            ),
          ),
        );
      },
    ),
  );
  }

  Widget _buildSettings(BuildContext context) {
    String t(String key) => AppLocalizations.tr(_controller.language, key);
    return _panelOverlay(
      title: t('settingsTitle'),
      subtitle: t('settingsSubtitle'),
      onBack: _controller.backToMenu,
      child: Column(
        children: [
          _setting(t('music'), t('musicDesc'), 'music'),
          _setting(t('ambience'), t('ambienceDesc'), 'ambience'),
          _setting(t('sfx'), t('sfxDesc'), 'sfx'),
          _setting(
            t('reducedMotion'),
            t('reducedMotionDesc'),
            'reducedMotion',
          ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => _controller.requestReset(),
          child: const Text(
            'Reset journey data',
            style: TextStyle(color: Color(0xffa34d42)),
          ),
        ),
      ],
    ),
    );
  }

  Widget _setting(String title, String description, String key) {
    final active = _controller.settings[key] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(13, 3, 5, 3),
      decoration: BoxDecoration(
        color: const Color(0xfff8efd9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: active,
        activeThumbColor: _leaf,
        title: Text(
          title,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(color: _ink, fontSize: 12),
        ),
        onChanged: (value) => _controller.updateSetting(key, value),
      ),
    );
  }

  Widget _buildDialogue(BuildContext context) {
    String t(String key) => AppLocalizations.tr(_controller.language, key);
    final friend = friends.firstWhere(
      (entry) => entry.id == _controller.activeFriendId,
      orElse: () => friends.first,
    );
    final delivery = _controller.activeDelivery;
    if (delivery == null) return const SizedBox.shrink();
    final alreadyDelivered = _controller.delivered.contains(friend.id);
    return _overlay(
      child: _paperPanel(
        maxWidth: 510,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Color(friend.color),
                foregroundColor: Colors.white,
                child: Text(
                  friend.name[0],
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${friend.name} the ${friendSpecies(friend, _controller.language)}',
                style: _titleStyle(24, color: Color(friend.color)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 9),
              Text(
                alreadyDelivered ? delivery.story : delivery.greeting,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _ink, height: 1.35),
              ),
              const SizedBox(height: 17),
              if (!alreadyDelivered)
                _button(
                  t('openMailbox'),
                  _controller.openPuzzle,
                  primary: true,
                  icon: Icons.mark_email_read_rounded,
                ),
              const SizedBox(height: 8),
              _button(
                alreadyDelivered ? t('backToPath') : t('deliverLater'),
                _controller.resumePath,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPuzzle(BuildContext context) {
    String t(String key) => AppLocalizations.tr(_controller.language, key);
    final friend = friends.firstWhere(
      (entry) => entry.id == _controller.activeFriendId,
      orElse: () => friends.first,
    );
    final puzzle = _controller.activePuzzle;
    if (puzzle == null) return const SizedBox.shrink();
    return _overlay(
      child: _paperPanel(
        maxWidth: 600,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${friend.name}’s mailbox lock",
                style: TextStyle(
                  color: Color(friend.color),
                  fontWeight: FontWeight.w900,
                  letterSpacing: .4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                puzzle.prompt,
                textAlign: TextAlign.center,
                style: _titleStyle(23),
              ),
              const SizedBox(height: 14),
              _puzzleVisual(puzzle),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 9,
                mainAxisSpacing: 9,
                children: puzzle.options
                    .map(
                      (option) => OutlinedButton(
                        onPressed: _controller.lastAnswerCorrect == true
                            ? null
                            : () => _controller.answerPuzzle(option),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _ink,
                          side: BorderSide(
                            color: Color(friend.color).withValues(alpha: .7),
                          ),
                          backgroundColor: const Color(0xfff8efd9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: Text(
                          option,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (_controller.activeAnswerMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _controller.activeAnswerMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _controller.lastAnswerCorrect == false
                        ? const Color(0xffa34d42)
                        : _leaf,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _controller.useHint,
                    icon: const Icon(Icons.lightbulb_outline_rounded),
                    label: Text(
                      '${t('hint')} · ${_controller.freeHints > 0 ? '${_controller.freeHints} free' : '✦ 3'}',
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _controller.resumePath,
                    child: Text(t('later')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _puzzleVisual(PuzzleData puzzle) {
    final groups = puzzle.visualGroups.clamp(1, 4);
    final items = puzzle.visualCount.clamp(1, 8);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        groups,
        (group) => Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xfff6edda),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 1,
                runSpacing: 1,
                children: List.generate(
                  items,
                  (_) => const Icon(
                    Icons.local_florist_rounded,
                    size: 17,
                    color: Color(0xff7d9b58),
                  ),
                ),
              ),
              if (groups > 1)
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Text(
                    '×${group + 1}',
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDelivery(BuildContext context) {
    String t(String key) => AppLocalizations.tr(_controller.language, key);
    final delivery = _controller.activeDelivery;
    if (delivery == null) return const SizedBox.shrink();
    return _overlay(
      child: _paperPanel(
        maxWidth: 520,
        child: Padding(
          padding: const EdgeInsets.all(23),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: _leaf,
                foregroundColor: Colors.white,
                child: Icon(Icons.check_rounded, size: 31),
              ),
              const SizedBox(height: 8),
              Text(t('deliveredTitle'), style: _titleStyle(28)),
              const SizedBox(height: 5),
              Text(
                delivery.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                delivery.letter,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _ink),
              ),
              const SizedBox(height: 9),
              Text(
                delivery.story,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _leaf,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                '+${delivery.reward} ${t('forestCoins')}   ·   ✦ ${_controller.coins}',
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              _button(
                _controller.delivered.length == friends.length
                    ? t('finishRoute')
                    : t('continuePath'),
                _controller.continueFromDelivery,
                primary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComplete(BuildContext context) {
    String t(String key) => AppLocalizations.tr(_controller.language, key);
    final records = _controller.worldRecords;
    final record =
        records['${_controller.completedWorldId}'] as Map<String, dynamic>?;
    final stars = (record?['stars'] as num?)?.toInt() ?? 1;
    final world = worldFor(_controller.completedWorldId, _controller.language);
    return _overlay(
      child: _paperPanel(
        maxWidth: 520,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _controller.language == 'id'
                    ? 'RUTE ${world.id} SELESAI'
                    : 'ROUTE ${world.id} COMPLETE',
                style: const TextStyle(
                  color: _leaf,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                world.name,
                style: _titleStyle(30),
                textAlign: TextAlign.center,
              ),
              Text(
                '★' * stars + '☆' * (3 - stars),
                style: const TextStyle(color: Color(0xffd6a336), fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                t('completeSubtitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: _ink),
              ),
              const SizedBox(height: 18),
              _button(
                world.id == 25 ? t('seeEnding') : t('nextWorld'),
                _controller.nextWorld,
                primary: true,
                icon: Icons.arrow_forward_rounded,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _button(t('worldMap'), () => _controller.openMap()),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _button(
                      t('replay'),
                      () => _controller.startWorld(world.id, replay: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnding(BuildContext context) {
    String t(String key) => AppLocalizations.tr(_controller.language, key);
    return _overlay(
    child: _paperPanel(
      maxWidth: 560,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wb_twilight_rounded,
              size: 47,
              color: Color(0xffd6a336),
            ),
            Text(
              t('endingTitle'),
              style: _titleStyle(27),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              t('endingBody'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _ink, height: 1.35),
            ),
            const SizedBox(height: 12),
            Text(
              t('endingThanks'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _leaf, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 17),
            _button(
              t('endingReturn'),
              _controller.openMap,
              primary: true,
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildTutorial(BuildContext context) {
    String t(String key) => AppLocalizations.tr(_controller.language, key);
    final steps = <(IconData, String, String)>[
      (Icons.directions_walk_rounded, t('tutMove'), t('tutMoveDesc')),
      (Icons.arrow_upward_rounded, t('tutJump'), t('tutJumpDesc')),
      (Icons.auto_awesome_rounded, t('tutInteract'), t('tutInteractDesc')),
      (Icons.lightbulb_outline_rounded, t('tutClue'), t('tutClueDesc')),
      (Icons.mark_email_read_rounded, t('tutDeliver'), t('tutDeliverDesc')),
      (Icons.star_rounded, t('tutGoal'), t('tutGoalDesc')),
    ];
    return _panelOverlay(
      title: t('howToPlay'),
      subtitle: t('howToSubtitle'),
      onBack: _controller.backFromTutorial,
      child: Column(
        children: steps
            .map(
              (step) => Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xfff8efd9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xffe3edd8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(step.$1, color: _leaf, size: 22),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.$2,
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            step.$3,
                            style: const TextStyle(color: _ink, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildConfirm(BuildContext context) {
    String t(String key) => AppLocalizations.tr(_controller.language, key);
    return _overlay(
    child: _paperPanel(
      maxWidth: 440,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t('confirmTitle'),
              style: _titleStyle(25),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              t('confirmDesc'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _ink),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _button(t('keepJourney'), _controller.cancelReset),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _button(
                    t('newJourneyBtn'),
                    _controller.resetJourney,
                    primary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _overlay({required Widget child}) => Container(
    color: const Color(0x330f231a),
    alignment: Alignment.center,
    padding: const EdgeInsets.all(14),
    child: child,
  );

  Widget _panelOverlay({
    required String title,
    required String subtitle,
    required VoidCallback onBack,
    required Widget child,
  }) => _overlay(
    child: _paperPanel(
      maxWidth: 760,
      maxHeight: MediaQuery.sizeOf(context).height * .9,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 9),
            child: Row(
              children: [
                _circleButton(
                  Icons.arrow_back_rounded,
                  'Back',
                  onBack,
                  size: 42,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: _titleStyle(23)),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _ink, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x33836e51)),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: child,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _paperPanel({
    required Widget child,
    double maxWidth = 600,
    double? maxHeight,
  }) => ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: maxWidth,
      maxHeight: maxHeight ?? MediaQuery.sizeOf(context).height * .9,
    ),
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_paper, Color(0xfffff2d8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xfff1e4ca), width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x550f231a),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    ),
  );

  Widget _button(
    String label,
    VoidCallback onPressed, {
    bool primary = false,
    IconData? icon,
  }) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: () {
        unawaited(_audio.playSfx('click'));
        onPressed();
      },
      icon: Icon(icon ?? Icons.auto_awesome_rounded, size: 18),
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      style: FilledButton.styleFrom(
        foregroundColor: primary ? Colors.white : _ink,
        backgroundColor: primary ? _leaf : _paperDeep,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );

  Widget _miniIcon(String tooltip, IconData icon, VoidCallback onPressed) =>
      Tooltip(
        message: tooltip,
        child: Material(
          color: const Color(0xfff8efd9),
          shape: const CircleBorder(),
          elevation: 1,
          child: InkWell(
            onTap: () {
              unawaited(_audio.playSfx('click'));
              onPressed();
            },
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(icon, color: _ink, size: 22),
            ),
          ),
        ),
      );

  Widget _badge(Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xeafff8e9),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0x88ffffff)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );

  Widget _circleButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    double size = 44,
  }) => Tooltip(
    message: tooltip,
    child: Material(
      color: const Color(0xeafff8e9),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: () {
          unawaited(_audio.playSfx('click'));
          onPressed();
        },
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: _ink, size: size * .54),
        ),
      ),
    ),
  );

  Widget _holdButton(String label, String tooltip, int direction) => Tooltip(
    message: tooltip,
    child: Listener(
      onPointerDown: (_) => _controller.setMove(direction, true),
      onPointerUp: (_) => _controller.setMove(direction, false),
      onPointerCancel: (_) => _controller.setMove(direction, false),
      child: Container(
        width: 62,
        height: 62,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xeafff8e9),
          borderRadius: BorderRadius.circular(19),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 34, color: _ink, height: 1),
        ),
      ),
    ),
  );

  Widget _controlButton(
    IconData icon,
    String label,
    VoidCallback onPressed, {
    bool wide = false,
  }) => Material(
    color: wide ? _leaf : const Color(0xeafff8e9),
    borderRadius: BorderRadius.circular(18),
    elevation: 3,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: wide ? 90 : 62,
        height: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: wide ? Colors.white : _ink, size: 23),
            Text(
              label,
              style: TextStyle(
                color: wide ? Colors.white : _ink,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  TextStyle _titleStyle(double size, {Color color = _ink}) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w900,
    height: 1.05,
    color: color,
    letterSpacing: -.5,
  );
}
