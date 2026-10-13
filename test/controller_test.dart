import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:postman/game/postman_controller.dart';
import 'package:postman/game/world_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('solving a mailbox puzzle records a delivery and its letter', () async {
    final controller = PostmanController();
    await controller.load();
    await controller.startWorld(1);
    controller.openDialogue('luna');
    controller.openPuzzle();

    final delivery = controller.activeDelivery!;
    final startingCoins = controller.coins;
    await controller.answerPuzzle(delivery.puzzle.answer);

    expect(controller.screen, GameScreen.delivery);
    expect(controller.delivered, contains('luna'));
    expect(controller.coins, startingCoins + delivery.reward);
    expect(controller.letters, hasLength(1));
    expect(controller.currentRecord['delivered'], contains('luna'));
    controller.dispose();
  });

  test('a fully progressed save can reach every world and equip every owned skin', () async {
    SharedPreferences.setMockInitialValues({
      'little_forest_postman_save_v1': jsonEncode({
        'version': 1,
        'unlockedWorld': 25,
        'purchasedSkins': playerSkins.map((skin) => skin.$1).toList(),
      }),
    });
    final controller = PostmanController();
    await controller.load();

    expect(controller.unlockedWorld, 25);
    await controller.selectWorld(25);
    expect(controller.worldId, 25);

    for (final skin in playerSkins) {
      await controller.selectSkin(skin.$1);
      expect(controller.selectedSkin, skin.$1);
    }
    controller.dispose();
  });

  test('worlds beyond the unlocked frontier stay locked', () async {
    final controller = PostmanController();
    await controller.load();

    expect(controller.unlockedWorld, 1);
    await controller.selectWorld(25);
    expect(controller.worldId, isNot(25));
    controller.dispose();
  });
}
