import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'world_data.dart';

class PostmanAudio {
  PostmanAudio();

  AudioPlayer? _musicPlayer;
  AudioPlayer? _ambiencePlayer;
  final Set<AudioPlayer> _activeSfxPlayers = <AudioPlayer>{};

  bool _unlocked = false;
  bool _musicEnabled = true;
  bool _ambienceEnabled = true;
  bool _sfxEnabled = true;
  bool _syncing = false;
  bool _syncAgain = false;
  String? _musicAsset;
  String? _ambienceAsset;
  String? _playingMusic;
  String? _playingAmbience;

  AudioContext _mixingAudioContext() => AudioContext(
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const <AVAudioSessionOptions>{
        AVAudioSessionOptions.mixWithOthers,
      },
    ),
  );

  void synchronize({
    required Map<String, dynamic> settings,
    required WorldData world,
    required bool inGame,
  }) {
    _musicEnabled = settings['music'] != false;
    _ambienceEnabled = settings['ambience'] != false;
    _sfxEnabled = settings['sfx'] != false;

    // Use the requested shared track in menus and during gameplay so replacing
    // bgm.mp3 is enough to hear music everywhere.
    _musicAsset = 'bgm.mp3';
    _ambienceAsset = inGame && _ambienceEnabled
        ? 'ambience_${world.weather}.mp3'
        : null;
    _scheduleSync();
  }

  /// Call directly from the first pointer/key gesture to satisfy browser audio policies.
  Future<void> unlock() async {
    _unlocked = true;
    _scheduleSync();
  }

  Future<void> playSfx(String name) async {
    if (!_unlocked || !_sfxEnabled) return;
    final player = AudioPlayer();
    _activeSfxPlayers.add(player);
    player.onPlayerComplete.listen((_) {
      _activeSfxPlayers.remove(player);
      unawaited(player.dispose());
    });
    try {
      await player.setAudioContext(_mixingAudioContext());
      await player.play(AssetSource('audio/$name.mp3'), volume: 0.72);
    } catch (_) {
      _activeSfxPlayers.remove(player);
      await player.dispose();
      // Keep gameplay running if a placeholder is temporarily being replaced.
    }
  }

  void _scheduleSync() {
    if (!_unlocked) return;
    if (_syncing) {
      _syncAgain = true;
      return;
    }
    _syncing = true;
    unawaited(_runSync());
  }

  Future<void> _runSync() async {
    do {
      _syncAgain = false;
      await _syncPlayers();
    } while (_syncAgain);
    _syncing = false;
  }

  Future<void> _syncPlayers() async {
    final nextMusic = _musicEnabled ? _musicAsset : null;
    if (nextMusic != _playingMusic) {
      try {
        final player = _musicPlayer ??= AudioPlayer();
        await player.setAudioContext(_mixingAudioContext());
        await player.stop();
        if (nextMusic != null) {
          await player.setReleaseMode(ReleaseMode.loop);
          await player.play(AssetSource('audio/$nextMusic'), volume: 0.35);
        }
        _playingMusic = nextMusic;
      } catch (_) {
        // Leave it retryable on the next gesture if the browser blocks playback.
        _playingMusic = null;
      }
    }

    final nextAmbience = _ambienceEnabled ? _ambienceAsset : null;
    if (nextAmbience != _playingAmbience) {
      try {
        final player = _ambiencePlayer ??= AudioPlayer();
        await player.setAudioContext(_mixingAudioContext());
        await player.stop();
        if (nextAmbience != null) {
          await player.setReleaseMode(ReleaseMode.loop);
          await player.play(AssetSource('audio/$nextAmbience'), volume: 0.42);
        }
        _playingAmbience = nextAmbience;
      } catch (_) {
        // Leave it retryable on the next gesture if playback is temporarily blocked.
        _playingAmbience = null;
      }
    }
  }

  Future<void> dispose() async {
    final players = <AudioPlayer>[
      ?_musicPlayer,
      ?_ambiencePlayer,
      ..._activeSfxPlayers,
    ];
    _activeSfxPlayers.clear();
    await Future.wait(players.map((player) => player.dispose()));
  }
}
