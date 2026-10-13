import 'package:flutter_test/flutter_test.dart';
import 'package:postman/game/world_data.dart';

void main() {
  test('all 25 worlds provide eight playable mailbox puzzles', () {
    for (final lang in ['en', 'id']) {
      for (var level = 1; level <= 25; level++) {
        final world = worldFor(level, lang);
        expect(world.id, level);
        expect(world.deliveries, hasLength(8));
        expect(world.npcPositions, hasLength(8));
        for (final delivery in world.deliveries) {
          expect(
            delivery.puzzle.options,
            contains(delivery.puzzle.answer),
            reason: 'world $level ($lang), ${delivery.friendId}',
          );
          expect(delivery.puzzle.options.length, greaterThanOrEqualTo(3));
        }
      }
    }
  });
}
