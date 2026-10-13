import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n.dart';
import 'postman_audio.dart';
import 'world_data.dart';

enum GameScreen {
  menu,
  play,
  routeSetup,
  map,
  friends,
  letters,
  wardrobe,
  settings,
  dialogue,
  puzzle,
  delivery,
  complete,
  ending,
  confirm,
  tutorial,
}

class PostmanController extends ChangeNotifier {
  PostmanController({PostmanAudio? audio}) : audio = audio ?? PostmanAudio();

  final PostmanAudio audio;
  static const _saveKey = 'little_forest_postman_save_v1';

  Map<String, dynamic> save = _defaultSave();
  GameScreen screen = GameScreen.menu;
  int sceneWorldId = 1;
  int completedWorldId = 1;
  bool mapFromGame = false;
  bool tutorialFromGame = false;
  double playerX = 260;
  double cameraX = 260;
  double playerY = 0;
  double velocityY = 0;
  int direction = 1;
  bool moveLeft = false;
  bool moveRight = false;
  bool reducedMotion = false;
  bool isMoving = false;
  String? activeFriendId;
  String? activeAnswerMessage;
  bool? lastAnswerCorrect;
  String? toast;
  int _toastVersion = 0;
  int _runHints = 0;
  int _runWrong = 0;
  double _stepDistance = 0;
  final Set<String> delivered = <String>{};
  final Set<String> _hintedThisRun = <String>{};
  final Set<String> _autoTriggered = <String>{};
  final Map<String, double> objectPositions = <String, double>{};
  int? heldPropIndex;
  int _puzzleVariant = 0;
  PuzzleData? _activePuzzle;
  int _wrongThisQuestion = 0;

  bool get onGround => playerY <= 0;
  int get worldId => sceneWorldId;
  int get coins => (save['coins'] as num?)?.toInt() ?? 12;
  int get unlockedWorld => (save['unlockedWorld'] as num?)?.toInt() ?? 1;
  bool get muted => save['muted'] == true;
  bool get tutorialSeen => save['tutorialSeen'] == true;
  String get selectedSkin => save['selectedSkin'] as String? ?? 'forest';
  String _l(String en, String idText) => language == 'id' ? idText : en;

  int get _activeFriendIndex => friends.indexWhere((f) => f.id == activeFriendId);

  WorldData get world => worldFor(worldId, language);

  PuzzleData? get activePuzzle {
    if (activeFriendId == null) return null;
    return _activePuzzle ?? activeDelivery?.puzzle;
  }
  List<Map<String, dynamic>> get letters =>
      (save['letters'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
  Map<String, dynamic> get settings =>
      Map<String, dynamic>.from(save['settings'] as Map? ?? const {});
  Map<String, dynamic> get currentRecord => _record(worldId);
  int get deliveredCount => delivered.length;
  String get language => save['language'] as String? ?? 'en';
  String get playMode => save['playMode'] as String? ?? 'story';
  int get freeHints {
    if (playMode == 'relaxed') return 99;
    if (playMode == 'challenge') return 0;
    return (_runHints < 2) ? 2 - _runHints : 0;
  }

  static Map<String, dynamic> _defaultSave() => {
    'version': 1,
    'currentWorld': 1,
    'unlockedWorld': 1,
    'currentX': 260,
    'coins': 12,
    'muted': false,
    'tutorialSeen': false,
    'worlds': <String, dynamic>{},
    'letters': <dynamic>[],
    'selectedSkin': 'forest',
    'purchasedSkins': <String>['forest'],
    'language': 'en',
    'playMode': 'story',
    'settings': <String, dynamic>{
      'music': true,
      'ambience': true,
      'sfx': true,
      'reducedMotion': false,
    },
  };

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic> && decoded['version'] == 1) {
          final base = _defaultSave();
          save = {...base, ...decoded};
          save['currentWorld'] = _boundedInt(save['currentWorld'], 1, 25, 1);
          save['unlockedWorld'] = _boundedInt(save['unlockedWorld'], 1, 25, 1);
          save['coins'] = _boundedInt(save['coins'], 0, 999999, 12);
          save['currentX'] = ((save['currentX'] as num?)?.toDouble() ?? 260)
              .clamp(70, 4750);
          save['worlds'] = Map<String, dynamic>.from(
            save['worlds'] as Map? ?? const {},
          );
          save['letters'] = (save['letters'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .take(200)
              .toList();
          save['settings'] = {
            ...base['settings'] as Map<String, dynamic>,
            ...Map<String, dynamic>.from(save['settings'] as Map? ?? const {}),
          };
          if (!playerSkins.any((skin) => skin.$1 == save['selectedSkin'])) {
            save['selectedSkin'] = 'forest';
          }
          if (!AppLocalizations.languages.contains(save['language'])) {
            save['language'] = 'en';
          }
          if (!const ['story', 'relaxed', 'challenge']
              .contains(save['playMode'])) {
            save['playMode'] = 'story';
          }
          if (save['purchasedSkins'] is! List) {
            save['purchasedSkins'] = <String>['forest'];
          }
        }
      } catch (_) {
        save = _defaultSave();
      }
    }
    if (save['purchasedSkins'] is! List || (save['purchasedSkins'] as List).isEmpty) {
      save['purchasedSkins'] = <String>['forest'];
    }
    sceneWorldId = (save['currentWorld'] as num?)?.toInt() ?? 1;
    final record = _record(worldId);
    delivered
      ..clear()
      ..addAll(
        (record['delivered'] as List<dynamic>? ?? const []).whereType<String>(),
      );
    playerX = ((save['currentX'] as num?)?.toDouble() ?? 260).clamp(70, 4750);
    cameraX = playerX;
    reducedMotion = settings['reducedMotion'] == true;
    if (!tutorialSeen) {
      tutorialFromGame = false;
      screen = GameScreen.tutorial;
      save['tutorialSeen'] = true;
      unawaited(persist());
    }
    notifyListeners();
  }

  static int _boundedInt(Object? value, int min, int max, int fallback) {
    if (value is! num) return fallback;
    return value.toInt().clamp(min, max);
  }

  Map<String, dynamic> _record(int id) {
    final worlds = save['worlds'] as Map<String, dynamic>;
    final key = '$id';
    if (worlds[key] is! Map<String, dynamic>) {
      worlds[key] = <String, dynamic>{
        'delivered': <String>[],
        'stars': 0,
        'hints': 0,
        'wrong': 0,
        'completed': false,
      };
    }
    return worlds[key] as Map<String, dynamic>;
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saveKey, jsonEncode(save));
  }

  Future<void> startWorld(int id, {bool replay = false}) async {
    final safeId = id.clamp(1, 25);
    final record = _record(safeId);
    if (safeId > unlockedWorld) return;
    _runHints = replay ? 0 : (record['hints'] as num?)?.toInt() ?? 0;
    _runWrong = replay ? 0 : (record['wrong'] as num?)?.toInt() ?? 0;
    _hintedThisRun.clear();
    _autoTriggered.clear();
    heldPropIndex = null;
    _puzzleVariant = 0;
    _activePuzzle = null;
    _wrongThisQuestion = 0;
    final savedWorld = (save['currentWorld'] as num?)?.toInt() ?? 1;
    final resumeX = (save['currentX'] as num?)?.toDouble() ?? 260;
    playerX = !replay && savedWorld == safeId && record['completed'] != true
        ? resumeX.clamp(70, 4750)
        : 260;
    cameraX = playerX;
    playerY = 0;
    velocityY = 0;
    direction = 1;
    moveLeft = false;
    moveRight = false;
    objectPositions.clear();
    delivered
      ..clear()
      ..addAll(
        replay
            ? const <String>[]
            : (record['delivered'] as List<dynamic>? ?? const [])
                  .whereType<String>(),
      );
    save['currentWorld'] = safeId;
    sceneWorldId = safeId;
    save['currentX'] = playerX.round();
    screen = GameScreen.play;
    activeFriendId = null;
    _stepDistance = 0;
    unawaited(audio.playSfx('level_start'));
    notifyListeners();
    await persist();
  }

  void updateGame(double dt) {
    if (screen != GameScreen.play) {
      isMoving = false;
      return;
    }
    if (playerY > 0 || velocityY > 0) {
      velocityY -= 1780 * dt;
      playerY += velocityY * dt;
      if (playerY <= 0) {
        playerY = 0;
        velocityY = 0;
        unawaited(audio.playSfx('land'));
      }
    }
    final input = (moveRight ? 1 : 0) - (moveLeft ? 1 : 0);
    isMoving = input != 0;
    if (input != 0) {
      direction = input;
      final previousX = playerX;
      playerX = (playerX + input * 260 * dt).clamp(70, 4750);
      _stepDistance += (playerX - previousX).abs();
      if (_stepDistance >= 78) {
        _stepDistance %= 78;
        unawaited(audio.playSfx('step'));
      }
    } else {
      _stepDistance = 0;
    }
    cameraX +=
        (playerX - cameraX) *
        (1 - math.pow(1 - (reducedMotion ? .18 : .09), dt * 60)).toDouble();
    if (playerX.round() % 140 == 0) {
      save['currentX'] = playerX.round();
    }
    final closeFriend = nearestFriend;
    if (closeFriend != null &&
        closeFriend.$2 < 74 &&
        !delivered.contains(closeFriend.$1.id) &&
        !_autoTriggered.contains(closeFriend.$1.id)) {
      _autoTriggered.add(closeFriend.$1.id);
      openDialogue(closeFriend.$1.id);
    }
  }

  (FriendData, double)? get nearestFriend {
    FriendData? result;
    var distance = double.infinity;
    for (final friend in friends) {
      final current = (world.npcPositions[friend.id]! - playerX).abs();
      if (current < distance) {
        result = friend;
        distance = current;
      }
    }
    return result == null ? null : (result, distance);
  }

  String? get nearbyPrompt {
    if (screen != GameScreen.play) return null;
    if (heldPropIndex != null) {
      return _l(
        'Holding ${propName(world.props[heldPropIndex!].frame, language)}',
        'Memegang ${propName(world.props[heldPropIndex!].frame, language)}',
      );
    }
    final nearest = nearestFriend;
    if (nearest != null && nearest.$2 < 125) {
      return delivered.contains(nearest.$1.id)
          ? _l('Give ${nearest.$1.name} a gentle pat', 'Belaikan ${nearest.$1.name} dengan lembut')
          : _l('Letter for ${nearest.$1.name}', 'Surat untuk ${nearest.$1.name}');
    }
    for (var index = 0; index < world.props.length; index++) {
      final prop = world.props[index];
      final x = objectPositions['${world.id}-$index'] ?? prop.x;
      if ((x - playerX).abs() < 105) return _l('Read the clue', 'Baca petunjuknya');
    }
    return null;
  }

  void setMove(int direction, bool pressed) {
    if (direction < 0) {
      moveLeft = pressed;
    } else {
      moveRight = pressed;
    }
  }

  void jump() {
    if (screen != GameScreen.play || !onGround) return;
    playerY = 1;
    velocityY = 650;
    unawaited(audio.playSfx('jump'));
  }

  void interact() {
    if (screen != GameScreen.play) return;
    if (heldPropIndex != null) {
      final index = heldPropIndex!;
      objectPositions['${world.id}-$index'] = (playerX + direction * 76).clamp(
        80,
        4740,
      );
      heldPropIndex = null;
      unawaited(audio.playSfx('drop'));
      showToast(_l('You set the object down.', 'Kau meletakkan benda itu.'));
      return;
    }
    final nearest = nearestFriend;
    if (nearest != null && nearest.$2 < 125) {
      if (delivered.contains(nearest.$1.id)) {
        unawaited(audio.playSfx('pet'));
        showToast(_l(
          '${nearest.$1.name} leans into a gentle pat.',
          '${nearest.$1.name} menyender menerima belaian lembut.',
        ));
      } else {
        openDialogue(nearest.$1.id);
      }
      return;
    }
    PropData? nearestProp;
    var distance = double.infinity;
    var nearestIndex = -1;
    for (var index = 0; index < world.props.length; index++) {
      final prop = world.props[index];
      final x = objectPositions['${world.id}-$index'] ?? prop.x;
      final current = (x - playerX).abs();
      if (current < distance) {
        distance = current;
        nearestProp = prop;
        nearestIndex = index;
      }
    }
    if (nearestProp != null && distance < 125) {
      const holdable = {
        'umbrella',
        'basket',
        'crate',
        'book_stack',
        'rock_stack',
        'parcel_cart',
      };
      if (holdable.contains(nearestProp.frame)) {
        heldPropIndex = nearestIndex;
        unawaited(audio.playSfx('pickup'));
        showToast(
          _l(
            'Holding the ${propName(nearestProp.frame, language)}. Tap Interact to put it down.',
            'Memegang ${propName(nearestProp.frame, language)}. Ketuk Interact untuk meletakkannya.',
          ),
        );
      } else {
        unawaited(audio.playSfx('interact'));
        showToast(nearestProp.clue, seconds: 4);
      }
    } else {
      showToast(
        world.id == 1
            ? _l(
                'Try the first sparkling sign, then follow the path.',
                'Coba tanda berkilau pertama, lalu ikuti jalannya.',
              )
            : world.ambience,
      );
    }
  }

  void openDialogue(String friendId) {
    if (screen != GameScreen.play) return;
    _autoTriggered.add(friendId);
    activeFriendId = friendId;
    screen = GameScreen.dialogue;
    moveLeft = false;
    moveRight = false;
    unawaited(audio.playSfx('dialogue'));
    notifyListeners();
  }

  void openPuzzle() {
    if (activeFriendId == null) return;
    activeAnswerMessage = null;
    lastAnswerCorrect = null;
    _puzzleVariant = 0;
    _activePuzzle = null;
    _wrongThisQuestion = 0;
    screen = GameScreen.puzzle;
    unawaited(audio.playSfx('puzzle_open'));
    notifyListeners();
  }

  DeliveryData? get activeDelivery {
    final friendId = activeFriendId;
    if (friendId == null) return null;
    return world.deliveryFor(friendId);
  }

  Future<void> answerPuzzle(String choice) async {
    final delivery = activeDelivery;
    if (delivery == null) return;
    final puzzle = activePuzzle;
    if (puzzle == null) return;
    if (choice == puzzle.answer) {
      unawaited(audio.playSfx('correct'));
      activeAnswerMessage = _l(
        'The number story fits. The mailbox is opening…',
        'Cerita angkanya pas. Kotak surat terbuka…',
      );
      lastAnswerCorrect = true;
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 550));
      await _completeDelivery(delivery);
    } else {
      unawaited(audio.playSfx('wrong'));
      _runWrong++;
      _record(worldId)['wrong'] = _runWrong;
      _wrongThisQuestion++;
      if (_wrongThisQuestion >= 2 && _activeFriendIndex >= 0) {
        _puzzleVariant++;
        _activePuzzle = makePuzzle(
          worldId,
          _activeFriendIndex,
          friends[_activeFriendIndex].item,
          language,
          _puzzleVariant,
        );
        _wrongThisQuestion = 0;
        activeAnswerMessage = _l(
          'A new question at the same level. Try again!',
          'Soal baru dengan level yang sama. Coba lagi!',
        );
        lastAnswerCorrect = null;
        await persist();
        notifyListeners();
      } else {
        activeAnswerMessage = _l(
          'Not quite. The letter is safe—look at the groups and try again.',
          'Belum tepat. Suratnya aman—perhatikan kelompoknya dan coba lagi.',
        );
        lastAnswerCorrect = false;
        await persist();
        notifyListeners();
      }
    }
  }

  Future<void> useHint() async {
    final delivery = activeDelivery;
    if (delivery == null) return;
    final hint = activePuzzle?.hint ?? delivery.puzzle.hint;
    if (_hintedThisRun.contains(delivery.friendId)) {
      unawaited(audio.playSfx('hint'));
      activeAnswerMessage = hint;
      lastAnswerCorrect = null;
      notifyListeners();
      return;
    }
    if (freeHints <= 0) {
      final cost = playMode == 'challenge' ? 5 : 3;
      if (coins < cost) {
        unawaited(audio.playSfx('error'));
        activeAnswerMessage = _l(
          'This hint costs $cost Forest Coins. You can return after another delivery.',
          'Petunjuk ini memakan $cost Koin Hutan. Kau bisa kembali setelah mengantar surat lain.',
        );
        lastAnswerCorrect = null;
        notifyListeners();
        return;
      }
      save['coins'] = coins - cost;
    } else if (playMode != 'relaxed') {
      _runHints++;
    }
    _hintedThisRun.add(delivery.friendId);
    unawaited(audio.playSfx('hint'));
    _record(worldId)['hints'] = _runHints;
    activeAnswerMessage = hint;
    lastAnswerCorrect = null;
    await persist();
    notifyListeners();
  }

  Future<void> _completeDelivery(DeliveryData delivery) async {
    if (delivered.contains(delivery.friendId)) return;
    delivered.add(delivery.friendId);
    save['coins'] = coins + delivery.reward;
    final letterId = '$worldId-${delivery.friendId}';
    final collection = save['letters'] as List<dynamic>;
    if (!collection.any((entry) => entry is Map && entry['id'] == letterId)) {
      collection.add(<String, dynamic>{
        'id': letterId,
        'world': worldId,
        'friendId': delivery.friendId,
        'title': delivery.title,
        'letter': delivery.letter,
        'story': delivery.story,
      });
    }
    final record = _record(worldId);
    record['delivered'] = delivered.toList();
    record['hints'] = _runHints;
    record['wrong'] = _runWrong;
    save['currentX'] = playerX.round();
    screen = GameScreen.delivery;
    unawaited(audio.playSfx('unlock'));
    unawaited(audio.playSfx('letter'));
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        unawaited(audio.playSfx('coin'));
      }),
    );
    await persist();
    notifyListeners();
  }

  Future<void> continueFromDelivery() async {
    if (delivered.length >= friends.length) {
      await completeWorld();
    } else {
      screen = GameScreen.play;
      activeFriendId = null;
      showToast(
        _l(
          'Another letter is still waiting in the satchel. Look for a friend on the path.',
          'Masih ada surat menunggu di pelana. Carilah seorang teman di jalan.',
        ),
      );
      notifyListeners();
    }
  }

  Future<void> completeWorld() async {
    final record = _record(worldId);
    final stars = playMode == 'relaxed'
        ? 3
        : (_runHints == 0 && _runWrong <= 2
              ? 3
              : (_runHints <= 2 && _runWrong <= 8 ? 2 : 1));
    record['completed'] = true;
    record['delivered'] = friends.map((friend) => friend.id).toList();
    record['stars'] = math.max((record['stars'] as num?)?.toInt() ?? 0, stars);
    record['hints'] = _runHints;
    record['wrong'] = _runWrong;
    save['coins'] = coins + stars * 6;
    save['unlockedWorld'] = math.max(unlockedWorld, math.min(25, worldId + 1));
    save['currentWorld'] = math.min(25, worldId + 1);
    save['currentX'] = 260;
    completedWorldId = worldId;
    screen = GameScreen.complete;
    unawaited(audio.playSfx('win'));
    unawaited(audio.playSfx('star'));
    await persist();
    notifyListeners();
  }

  Future<void> nextWorld() async {
    if (worldId == 25) {
      screen = GameScreen.ending;
      unawaited(audio.playSfx('ending'));
      notifyListeners();
      return;
    }
    await startWorld(worldId + 1);
  }

  Future<void> selectWorld(int id) async {
    if (id > unlockedWorld) return;
    final record = _record(id);
    await startWorld(id, replay: record['completed'] == true);
  }

  void openMap({bool fromGame = false}) {
    moveLeft = false;
    moveRight = false;
    mapFromGame = fromGame;
    if (fromGame) {
      save['currentWorld'] = worldId;
      save['currentX'] = playerX.round();
      unawaited(persist());
    }
    screen = GameScreen.map;
    notifyListeners();
  }

  void backFromMap() => mapFromGame ? resumePath() : backToMenu();

  void openMenu() {
    moveLeft = false;
    moveRight = false;
    screen = GameScreen.menu;
    save['currentX'] = playerX.round();
    unawaited(persist());
    notifyListeners();
  }

  void openFriends() => _setScreen(GameScreen.friends);
  void openLetters() => _setScreen(GameScreen.letters);
  void openWardrobe() => _setScreen(GameScreen.wardrobe);
  void openSettings() => _setScreen(GameScreen.settings);
  void openRouteSetup() => _setScreen(GameScreen.routeSetup);
  void openTutorial({bool fromGame = false}) {
    tutorialFromGame = fromGame;
    _setScreen(GameScreen.tutorial);
  }

  void backFromTutorial() => tutorialFromGame ? resumePath() : backToMenu();
  void requestReset() => _setScreen(GameScreen.confirm);
  void cancelReset() => _setScreen(GameScreen.menu);
  void resumePath() {
    unawaited(audio.playSfx('back'));
    _setScreen(GameScreen.play);
  }

  void backToMenu() {
    sceneWorldId = (save['currentWorld'] as num?)?.toInt() ?? 1;
    playerX = ((save['currentX'] as num?)?.toDouble() ?? 260).clamp(70, 4750);
    cameraX = playerX;
    _setScreen(GameScreen.menu);
  }

  void _setScreen(GameScreen next) {
    screen = next;
    notifyListeners();
  }

  String biography(FriendData friend) {
    final completed = ((save['worlds'] as Map<String, dynamic>).values
        .whereType<Map>()
        .where((r) => r['completed'] == true)
        .length);
    final stage = math.min(4, math.max(0, completed - 1) ~/ 5);
    final stages = language == 'id'
        ? storyStagesId[friend.id]!.first
        : storyStages[friend.id]!.first;
    return stages[stage];
  }

  bool isSkinOwned(String skin) =>
      (save['purchasedSkins'] as List? ?? const []).contains(skin);

  int skinCost(String skin) => skinCosts[skin] ?? 0;

  Future<void> selectSkin(String skin) async {
    if (isSkinOwned(skin)) {
      save['selectedSkin'] = skin;
      unawaited(audio.playSfx('select'));
      await persist();
      notifyListeners();
      return;
    }
    final cost = skinCost(skin);
    if (coins < cost) {
      showToast(
        _l(
          'Not enough Forest Coins to get that outfit.',
          'Koin Hutan kurang untuk membeli tampilan itu.',
        ),
      );
      return;
    }
    save['coins'] = coins - cost;
    (save['purchasedSkins'] as List).add(skin);
    save['selectedSkin'] = skin;
    unawaited(audio.playSfx('select'));
    unawaited(audio.playSfx('coin'));
    await persist();
    notifyListeners();
  }

  Future<void> selectLanguage(String lang) async {
    if (!AppLocalizations.languages.contains(lang)) return;
    save['language'] = lang;
    unawaited(audio.playSfx('select'));
    await persist();
    notifyListeners();
  }

  Future<void> selectPlayMode(String mode) async {
    if (!const ['story', 'relaxed', 'challenge'].contains(mode)) return;
    save['playMode'] = mode;
    unawaited(audio.playSfx('select'));
    await persist();
    notifyListeners();
  }

  Future<void> toggleMute() async {
    save['muted'] = !muted;
    await persist();
    notifyListeners();
  }

  /// Persist the current state immediately, e.g. when the app is backgrounded
  /// or closed abruptly so progress is never lost.
  Future<void> saveNow() async {
    if (screen == GameScreen.play) {
      save['currentWorld'] = sceneWorldId;
      save['currentX'] = playerX.round();
    }
    await persist();
  }

  Future<void> updateSetting(String key, bool value) async {
    final current = Map<String, dynamic>.from(save['settings'] as Map);
    current[key] = value;
    unawaited(audio.playSfx('toggle'));
    save['settings'] = current;
    reducedMotion = current['reducedMotion'] == true;
    await persist();
    notifyListeners();
  }

  Future<void> resetJourney() async {
    save = _defaultSave();
    delivered.clear();
    playerX = cameraX = 260;
    sceneWorldId = 1;
    playerY = velocityY = 0;
    screen = GameScreen.menu;
    await persist();
    notifyListeners();
  }

  void showToast(String message, {int seconds = 3}) {
    toast = message;
    final version = ++_toastVersion;
    notifyListeners();
    Future<void>.delayed(Duration(seconds: seconds), () {
      if (version == _toastVersion) {
        toast = null;
        notifyListeners();
      }
    });
  }

  Map<String, dynamic> get worldRecords =>
      save['worlds'] as Map<String, dynamic>;
}
